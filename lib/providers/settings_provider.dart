import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _defaultCurrency = 'IDR';
  String _currencySymbol = 'Rp';

  bool get isDarkMode => _isDarkMode;
  String get defaultCurrency => _defaultCurrency;
  String get currencySymbol => _currencySymbol;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isDarkMode = await SettingsService.getDarkMode();
    _defaultCurrency = await SettingsService.getDefaultCurrency();
    _currencySymbol = await SettingsService.getCurrencySymbol();
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await SettingsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setCurrency(String code, String symbol) async {
    _defaultCurrency = code;
    _currencySymbol = symbol;
    await SettingsService.setCurrency(code, symbol);
    notifyListeners();
  }
}
