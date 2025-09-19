enum WalletType { physical, bankAccount, crypto, investment, other }

class Wallet {
  const Wallet({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.balance = 0.0,
    this.iconName = 'account_balance_wallet',
    this.color = '',
    this.type = WalletType.physical,
    this.currencyCode = 'USD',
  });

  final String id;
  final String userId;
  final String name;
  final double balance;
  final String iconName;
  final String color;
  final WalletType type;
  final String currencyCode;

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    String? iconName,
    String? color,
    WalletType? type,
    String? currencyCode,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      iconName: json['iconName'] as String? ?? 'account_balance_wallet',
      color: json['color'] as String? ?? '',
      type: WalletType.values.firstWhere(
        (value) => value.name == (json['type'] as String?),
        orElse: () => WalletType.physical,
      ),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      'iconName': iconName,
      'color': color,
      'type': type.name,
      'currencyCode': currencyCode,
    };
  }
}
