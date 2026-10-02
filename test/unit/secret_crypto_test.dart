import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/utils/secret_crypto.dart';

void main() {
  group('SecretCrypto Tests', () {
    test('Encrypt and decrypt roundtrip preserves exact plaintext secret', () {
      const originalSecret = 'twitch_client_secret_998877665544332211aabbcc';

      final encrypted = SecretCrypto.encrypt(originalSecret);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(originalSecret)));

      final decrypted = SecretCrypto.decrypt(encrypted);
      expect(decrypted, equals(originalSecret));
    });

    test('Encrypt produces unique ciphertexts for identical plaintext due to random IV', () {
      const secret = 'my_super_secret_value_123';

      final encrypted1 = SecretCrypto.encrypt(secret);
      final encrypted2 = SecretCrypto.encrypt(secret);

      expect(encrypted1, isNot(equals(encrypted2)));
      expect(SecretCrypto.decrypt(encrypted1), equals(secret));
      expect(SecretCrypto.decrypt(encrypted2), equals(secret));
    });

    test('Decrypting empty or corrupted string returns null gracefully', () {
      expect(SecretCrypto.decrypt(''), isNull);
      expect(SecretCrypto.decrypt('   '), isNull);
      expect(SecretCrypto.decrypt('invalid_base_64!!!'), isNull);
      expect(SecretCrypto.decrypt('YWJj'), isNull); // Valid base64 but shorter than 16 byte IV
    });

    test('Mask generates expected bullet strings for write-only UI representation', () {
      expect(SecretCrypto.mask(8), equals('••••••••'));
      expect(SecretCrypto.mask(16), equals('••••••••••••••••'));
    });
  });
}
