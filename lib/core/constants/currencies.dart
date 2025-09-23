import 'package:flutter/material.dart';

@immutable
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    this.symbol,
  });

  final String code;
  final String name;
  final String? symbol;

  String get label {
    if (symbol != null && symbol!.isNotEmpty) {
      return '$code · ${symbol!} $name';
    }
    return '$code · $name';
  }
}

/// Default currency
const CurrencyOption kDefaultCurrency =
    CurrencyOption(code: 'USD', name: 'US Dollar', symbol: '\$');

/// List of supported currencies
const List<CurrencyOption> kCurrencyOptions = [
  kDefaultCurrency,
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
  CurrencyOption(code: 'AUD', name: 'Australian Dollar', symbol: '\$'),
  CurrencyOption(code: 'CAD', name: 'Canadian Dollar', symbol: '\$'),
  CurrencyOption(code: 'NZD', name: 'New Zealand Dollar', symbol: '\$'),
  CurrencyOption(code: 'SGD', name: 'Singapore Dollar', symbol: '\$'),
  CurrencyOption(code: 'HKD', name: 'Hong Kong Dollar', symbol: '\$'),
  CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  CurrencyOption(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  CurrencyOption(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
  CurrencyOption(code: 'THB', name: 'Thai Baht', symbol: '฿'),
  CurrencyOption(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
  CurrencyOption(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
  CurrencyOption(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
  CurrencyOption(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  CurrencyOption(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
  CurrencyOption(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
  CurrencyOption(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
  CurrencyOption(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
  CurrencyOption(code: 'PLN', name: 'Polish Złoty', symbol: 'zł'),
  CurrencyOption(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč'),
  CurrencyOption(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft'),
  CurrencyOption(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
  CurrencyOption(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
  CurrencyOption(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
  CurrencyOption(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼'),
  CurrencyOption(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'د.ك'),
  CurrencyOption(code: 'BHD', name: 'Bahraini Dinar', symbol: 'ب.د'),
  CurrencyOption(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
  CurrencyOption(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
  CurrencyOption(code: 'MXN', name: 'Mexican Peso', symbol: '\$'),
  CurrencyOption(code: 'CLP', name: 'Chilean Peso', symbol: '\$'),
  CurrencyOption(code: 'COP', name: 'Colombian Peso', symbol: '\$'),
  CurrencyOption(code: 'ARS', name: 'Argentine Peso', symbol: '\$'),
  CurrencyOption(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
  CurrencyOption(code: 'NGN', name: 'Nigerian Naira', symbol: '₦'),
  CurrencyOption(code: 'EGP', name: 'Egyptian Pound', symbol: '£'),
  CurrencyOption(code: 'ILS', name: 'Israeli Shekel', symbol: '₪'),
];

/// Fast lookup by currency code
final Map<String, CurrencyOption> _currencyByCode = {
  for (final option in kCurrencyOptions) option.code: option,
};

/// Get currency by code, fallback to default
CurrencyOption currencyOptionFor(String? code) {
  final normalized = code?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return kDefaultCurrency;
  }
  return _currencyByCode[normalized] ?? kDefaultCurrency;
}

/// Build dropdown items for UI
List<DropdownMenuItem<String>> buildCurrencyDropdownItems() {
  return kCurrencyOptions
      .map(
        (option) => DropdownMenuItem<String>(
          value: option.code,
          child: Text(option.label),
        ),
      )
      .toList(growable: false);
}
