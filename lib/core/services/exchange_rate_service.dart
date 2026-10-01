import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../storage/hive_registrar.dart';

class ExchangeRates {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime lastUpdated;

  const ExchangeRates({
    this.baseCurrency = 'USD',
    required this.rates,
    required this.lastUpdated,
  });

  /// Hardcoded initial seed rates matching offline defaults.
  /// 1 USD = X units of foreign currency.
  /// Standardized so:
  /// 100 USD = 92.59 EUR
  /// 1000 INR = 12.00 USD (100 USD = 8333.33 INR)
  /// 100 USD = 78.13 GBP
  factory ExchangeRates.seed() {
    return ExchangeRates(
      baseCurrency: 'USD',
      rates: const {
        'USD': 1.0,
        'EUR': 0.925926,
        'GBP': 0.78125,
        'INR': 83.333333,
        'JPY': 149.2537,
        'CAD': 1.3514,
        'AUD': 1.5152,
      },
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isSeed => lastUpdated.millisecondsSinceEpoch == 0;

  double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    final fromUpper = from.toUpperCase().trim();
    final toUpper = to.toUpperCase().trim();
    if (fromUpper == toUpper) return amount;

    final fromRate = rates[fromUpper] ?? ExchangeRates.seed().rates[fromUpper] ?? 1.0;
    final toRate = rates[toUpper] ?? ExchangeRates.seed().rates[toUpper] ?? 1.0;

    if (fromRate <= 0) return amount;
    final inBase = amount / fromRate;
    final converted = inBase * toRate;
    return double.parse(converted.toStringAsFixed(2));
  }

  Map<String, dynamic> toMap() {
    return {
      'baseCurrency': baseCurrency,
      'rates': rates,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ExchangeRates.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedDate;
    if (map['lastUpdated'] is String) {
      parsedDate = DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawRates = map['rates'];
    final ratesMap = <String, double>{};
    if (rawRates is Map) {
      rawRates.forEach((k, v) {
        if (v is num) {
          ratesMap[k.toString().toUpperCase()] = v.toDouble();
        }
      });
    }

    // Ensure our supported currencies always have at least fallback rates
    for (final entry in ExchangeRates.seed().rates.entries) {
      ratesMap.putIfAbsent(entry.key, () => entry.value);
    }

    return ExchangeRates(
      baseCurrency: map['baseCurrency']?.toString().toUpperCase() ?? 'USD',
      rates: ratesMap,
      lastUpdated: parsedDate,
    );
  }
}

class ExchangeRateService {
  static const String storageKey = 'cached_exchange_rates';
  static const String _primaryApiUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _secondaryApiUrl = 'https://api.frankfurter.app/latest?from=USD';
  static const Duration syncCooldown = Duration(hours: 24);

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// Checks if a sync is allowed according to the 24-hour limit
  static bool canSync({ExchangeRates? rates}) {
    final active = rates ?? loadFromStorage();
    if (active.isSeed) return true;
    final difference = DateTime.now().difference(active.lastUpdated);
    return difference >= syncCooldown;
  }

  /// Calculates the remaining cooldown time before next sync is permitted
  static Duration timeUntilNextSync({ExchangeRates? rates}) {
    final active = rates ?? loadFromStorage();
    if (active.isSeed) return Duration.zero;
    final elapsed = DateTime.now().difference(active.lastUpdated);
    if (elapsed >= syncCooldown) return Duration.zero;
    return syncCooldown - elapsed;
  }

  /// Human-friendly representation of remaining cooldown (e.g., "4h", "8h", or "45m" when <1h)
  static String formatCooldownRemaining(Duration remaining) {
    if (remaining.inSeconds <= 0) return 'Available now';
    final hours = remaining.inHours;
    if (hours > 0) {
      return '${hours}h';
    } else {
      final minutes = remaining.inMinutes;
      if (minutes > 0) {
        return '${minutes}m';
      }
      return '<1m';
    }
  }

  /// Loads persisted exchange rates from Hive local storage
  static ExchangeRates loadFromStorage() {
    try {
      if (Hive.isBoxOpen(HiveRegistrar.settingsBoxName)) {
        final raw = HiveRegistrar.settingsBox.get(storageKey);
        if (raw is Map) {
          return ExchangeRates.fromMap(raw);
        }
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Error loading rates from storage: $e');
    }
    return ExchangeRates.seed();
  }

  /// Saves the fetched exchange rates into Hive local storage
  static Future<void> saveToStorage(ExchangeRates exchangeRates) async {
    try {
      if (Hive.isBoxOpen(HiveRegistrar.settingsBoxName)) {
        await HiveRegistrar.settingsBox.put(storageKey, exchangeRates.toMap());
        debugPrint('[ExchangeRateService] Saved exchange rates to storage (${exchangeRates.rates.length} rates, updated: ${exchangeRates.lastUpdated}).');
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Error saving rates to storage: $e');
    }
  }

  /// Fetches latest rates from network and immediately updates local storage.
  /// Hard-limited by 24h cooldown unless [force] is true.
  /// Returns the updated ExchangeRates if successful, or null if network request failed / cooldown active.
  static Future<ExchangeRates?> fetchAndPersistLatestRates({bool force = false}) async {
    final stored = loadFromStorage();
    if (!force && !canSync(rates: stored)) {
      debugPrint('[ExchangeRateService] Sync skipped: 24-hour rate limit active. Next sync in: ${formatCooldownRemaining(timeUntilNextSync(rates: stored))}');
      return null;
    }

    // 1. Try Primary Open ER API
    try {
      final response = await _dio.get<dynamic>(_primaryApiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> json;
        if (response.data is Map<String, dynamic>) {
          json = response.data as Map<String, dynamic>;
        } else {
          json = jsonDecode(response.data.toString()) as Map<String, dynamic>;
        }

        if (json['rates'] is Map) {
          final ratesMap = <String, double>{'USD': 1.0};
          final rawRates = json['rates'] as Map;
          for (final code in ['EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD']) {
            if (rawRates[code] is num) {
              ratesMap[code] = (rawRates[code] as num).toDouble();
            }
          }

          final exchangeRates = ExchangeRates(
            baseCurrency: 'USD',
            rates: ratesMap,
            lastUpdated: DateTime.now(),
          );

          await saveToStorage(exchangeRates);
          return exchangeRates;
        }
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Primary exchange rates fetch failed: $e');
    }

    // 2. Try Secondary Frankfurter API
    try {
      final response = await _dio.get<dynamic>(_secondaryApiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> json;
        if (response.data is Map<String, dynamic>) {
          json = response.data as Map<String, dynamic>;
        } else {
          json = jsonDecode(response.data.toString()) as Map<String, dynamic>;
        }

        if (json['rates'] is Map) {
          final ratesMap = <String, double>{'USD': 1.0};
          final rawRates = json['rates'] as Map;
          for (final code in ['EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD']) {
            if (rawRates[code] is num) {
              ratesMap[code] = (rawRates[code] as num).toDouble();
            }
          }

          final exchangeRates = ExchangeRates(
            baseCurrency: 'USD',
            rates: ratesMap,
            lastUpdated: DateTime.now(),
          );

          await saveToStorage(exchangeRates);
          return exchangeRates;
        }
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Secondary exchange rates fetch failed: $e');
    }

    return null;
  }
}
