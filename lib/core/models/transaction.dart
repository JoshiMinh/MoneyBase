import 'package:cloud_firestore/cloud_firestore.dart';

class MoneyBaseTransaction {
  MoneyBaseTransaction({
    this.id = '',
    this.userId = '',
    this.description = '',
    this.amount = 0.0,
    this.currencyCode = 'USD',
    this.isIncome = false,
    this.categoryId = '',
    this.walletId = '',
    DateTime? date,
    DateTime? createdAt,
  }) : date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String userId;
  final String description;
  final double amount;
  final String currencyCode;
  final bool isIncome;
  final String categoryId;
  final String walletId;
  final DateTime date;
  final DateTime createdAt;

  MoneyBaseTransaction copyWith({
    String? id,
    String? userId,
    String? description,
    double? amount,
    String? currencyCode,
    bool? isIncome,
    String? categoryId,
    String? walletId,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return MoneyBaseTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      isIncome: isIncome ?? this.isIncome,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MoneyBaseTransaction.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return MoneyBaseTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      isIncome: json['isIncome'] as bool? ?? false,
      categoryId: json['categoryId'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
      date: parseDate(json['date']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'description': description,
    'amount': amount,
    'currencyCode': currencyCode,
    'isIncome': isIncome,
    'categoryId': categoryId,
    'walletId': walletId,
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
