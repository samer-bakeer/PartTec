import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../utils/session_store.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = "USD";
  double _rate = 15000;

  String get currency => _currency;
  double get rate => _rate;

  Future<void> loadCurrency() async {
    final saved = await SessionStore.getCurrency();
    _currency = saved ?? "USD";

    await fetchRate();

    notifyListeners();
  }

  Future<void> fetchRate() async {
    _rate = await CurrencyService.getUsdToSypRate();
  }

  Future<void> changeCurrency(String newCurrency) async {
    _currency = newCurrency;

    await SessionStore.setCurrency(newCurrency);

    notifyListeners();
  }

  String formatPrice(double price) {
    if (_currency == "SYP") {
      final syp = price * _rate;
      return "${syp.toStringAsFixed(0)} ل.س";
    }

    return "\$${price.toStringAsFixed(2)}";
  }
}
