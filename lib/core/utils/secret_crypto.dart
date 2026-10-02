import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic utility for securing sensitive user API secrets (such as Twitch Client Secret)
/// in local storage, ensuring secrets are never persisted in plaintext.
class SecretCrypto {
  static const String _defaultSalt = 'lycoris_vault_api_credentials_salt_2026';

  /// Derives a 32-byte key from a given salt using SHA-256
  static List<int> _deriveKey([String? customSalt]) {
    final salt = customSalt ?? _defaultSalt;
    return sha256.convert(utf8.encode(salt)).bytes;
  }

  /// Encrypts [plaintext] using HMAC-SHA256 in Counter (CTR) mode with a cryptographically
  /// secure 16-byte random IV. Returns a Base64-encoded string: `IV (16 bytes) + Ciphertext`.
  static String encrypt(String plaintext, {String? salt}) {
    if (plaintext.isEmpty) return '';

    final key = _deriveKey(salt);
    final random = Random.secure();
    final iv = List<int>.generate(16, (_) => random.nextInt(256));

    final plainBytes = utf8.encode(plaintext);
    final cipherBytes = _applyHmacCtr(key, iv, plainBytes);

    final combined = Uint8List(iv.length + cipherBytes.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, cipherBytes);

    return base64Encode(combined);
  }

  /// Decrypts [ciphertextBase64] produced by [encrypt].
  /// Returns the original plaintext string, or null if the payload is invalid or corrupted.
  static String? decrypt(String ciphertextBase64, {String? salt}) {
    if (ciphertextBase64.trim().isEmpty) return null;

    try {
      final combined = base64Decode(ciphertextBase64.trim());
      if (combined.length <= 16) return null;

      final iv = combined.sublist(0, 16);
      final cipherBytes = combined.sublist(16);

      final key = _deriveKey(salt);
      final plainBytes = _applyHmacCtr(key, iv, cipherBytes);

      return utf8.decode(plainBytes);
    } catch (_) {
      return null;
    }
  }

  /// Helper to generate a masked string representation (e.g. `••••••••••••••••`)
  /// for write-only UI display so secrets cannot be inspected once saved.
  static String mask([int length = 16]) {
    return '•' * length;
  }

  /// Core stream cipher construction: XORs [input] with HMAC-SHA256 keystream
  static List<int> _applyHmacCtr(List<int> key, List<int> iv, List<int> input) {
    final output = Uint8List(input.length);
    final hmac = Hmac(sha256, key);

    var offset = 0;
    var counter = 0;

    while (offset < input.length) {
      // Counter block: 16 bytes IV + 4 bytes big-endian counter
      final counterBlock = Uint8List(20);
      counterBlock.setRange(0, 16, iv);
      final byteData = ByteData.view(counterBlock.buffer, 16, 4);
      byteData.setUint32(0, counter, Endian.big);

      final keystreamBlock = hmac.convert(counterBlock).bytes;
      final blockSize = min(keystreamBlock.length, input.length - offset);

      for (var i = 0; i < blockSize; i++) {
        output[offset + i] = input[offset + i] ^ keystreamBlock[i];
      }

      offset += blockSize;
      counter++;
    }

    return output;
  }
}
