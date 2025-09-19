class Currency {
  const Currency({
    this.code = 'USD',
    this.symbol = '\$',
    this.name = 'US Dollar',
    this.usdValue = 1.0,
  });

  final String code;
  final String symbol;
  final String name;
  final double usdValue;

  Currency copyWith({
    String? code,
    String? symbol,
    String? name,
    double? usdValue,
  }) {
    return Currency(
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      usdValue: usdValue ?? this.usdValue,
    );
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String? ?? 'USD',
      symbol: json['symbol'] as String? ?? '\$',
      name: json['name'] as String? ?? 'US Dollar',
      usdValue: (json['usdValue'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'symbol': symbol, 'name': name, 'usdValue': usdValue};
  }
}
