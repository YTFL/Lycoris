import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/exchange_rate_service.dart';

class ExchangeRatesNotifier extends StateNotifier<ExchangeRates> {
  ExchangeRatesNotifier() : super(ExchangeRateService.loadFromStorage());

  /// Automatically triggered when viewing screens (e.g. Analytics / Dashboard):
  /// Fetches fresh rates only if >= 24h since last sync
  Future<bool> checkAndAutoFetch() async {
    if (!ExchangeRateService.canSync(rates: state)) {
      return false;
    }
    final fresh = await ExchangeRateService.fetchAndPersistLatestRates();
    if (fresh != null) {
      state = fresh;
      return true;
    }
    return false;
  }

  /// Manually triggered by the user from Settings or Dashboard:
  /// Respects the 24h limit unless [force] is true.
  Future<bool> manualSync({bool force = false}) async {
    if (!force && !ExchangeRateService.canSync(rates: state)) {
      return false;
    }
    final fresh = await ExchangeRateService.fetchAndPersistLatestRates(force: force);
    if (fresh != null) {
      state = fresh;
      return true;
    }
    return false;
  }
}

final exchangeRatesNotifierProvider =
    StateNotifierProvider<ExchangeRatesNotifier, ExchangeRates>((ref) {
  return ExchangeRatesNotifier();
});
