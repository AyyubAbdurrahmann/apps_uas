import 'package:intl/intl.dart';

class CurrencyHelper {
  // Exchange rates (relative to IDR)
  // Update ini bisa dari API atau manual update
  static const Map<String, double> exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000062, // 1 IDR = 0.000062 USD
    'EUR': 0.000058, // 1 IDR = 0.000058 EUR
    'GBP': 0.000049, // 1 IDR = 0.000049 GBP
    'JPY': 0.0067, // 1 IDR = 0.0067 JPY
  };

  /// Get currency symbol dari currency code
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      case 'JPY':
        return '¥ ';
      default:
        return '$currencyCode ';
    }
  }

  /// Get locale untuk intl formatting berdasarkan currency
  static String getLocaleForCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'IDR':
        return 'id_ID';
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'JPY':
        return 'ja_JP';
      default:
        return 'en_US';
    }
  }

  /// Get decimal digits untuk setiap currency
  static int getDecimalDigits(String currencyCode) {
    switch (currencyCode) {
      case 'JPY':
        return 0; // JPY tidak punya decimal
      case 'IDR':
        return 0; // IDR tidak punya decimal
      default:
        return 2; // USD, EUR, GBP punya 2 decimal
    }
  }

  /// Convert amount dari satu currency ke currency lain
  /// Contoh: convertCurrency(5000000, 'IDR', 'USD') -> 310.0
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    if (fromCurrency == toCurrency) return amount;

    try {
      // Convert ke IDR dulu (base currency)
      final amountInIDR = amount / (exchangeRates[fromCurrency] ?? 1.0);

      // Convert dari IDR ke target currency
      final convertedAmount = amountInIDR * (exchangeRates[toCurrency] ?? 1.0);

      return convertedAmount;
    } catch (e) {
      print('Conversion error: $e');
      return amount;
    }
  }

  /// Format amount dengan currency yang sesuai dan auto-convert
  /// Contoh: formatCurrencyWithConversion(5000000, 'IDR', 'USD') -> '$ 310'
  static String formatCurrencyWithConversion(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    try {
      // Convert amount
      final convertedAmount = convertCurrency(amount, fromCurrency, toCurrency);

      // Format dengan currency tujuan
      final decimalDigits = getDecimalDigits(toCurrency);
      final locale = getLocaleForCurrency(toCurrency);
      final symbol = getCurrencySymbol(toCurrency);

      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: decimalDigits,
      );

      return formatter.format(convertedAmount);
    } catch (e) {
      print('Format error: $e');
      return '${getCurrencySymbol(toCurrency)}$amount';
    }
  }

  /// Format amount tanpa conversion (untuk display data original)
  /// Contoh: formatCurrency(5000000, 'IDR') -> 'Rp 5.000.000'
  static String formatCurrency(
    double amount,
    String currencyCode, {
    int? decimalDigits,
  }) {
    try {
      final digits = decimalDigits ?? getDecimalDigits(currencyCode);
      final locale = getLocaleForCurrency(currencyCode);
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: getCurrencySymbol(currencyCode),
        decimalDigits: digits,
      );
      return formatter.format(amount);
    } catch (e) {
      print('Format error: $e');
      return '${getCurrencySymbol(currencyCode)}${amount.toStringAsFixed(decimalDigits ?? 0)}';
    }
  }

  /// Format amount tanpa symbol (untuk display sederhana)
  static String formatAmount(
    double amount, {
    int decimalDigits = 0,
  }) {
    return amount.toStringAsFixed(decimalDigits);
  }

  /// List semua supported currencies
  static List<Map<String, String>> getSupportedCurrencies() {
    return [
      {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp '},
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$ '},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€ '},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£ '},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥ '},
    ];
  }

  /// Update exchange rates (bisa dipanggil dari API)
  static void updateExchangeRates(Map<String, double> newRates) {
    exchangeRates.clear();
    exchangeRates.addAll(newRates);
  }

  /// Get informasi rate untuk display
  static String getExchangeRateInfo(String from, String to) {
    final rate = convertCurrency(1, from, to);
    return '1 $from = ${rate.toStringAsFixed(4)} $to';
  }
}
