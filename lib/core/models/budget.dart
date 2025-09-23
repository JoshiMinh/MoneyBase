import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  const Budget({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.categoryId = '',
    this.currencyCode = 'USD',
    this.limit = 0.0,
    this.notes,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : startDate = startDate,
        endDate = endDate,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String name;
  final String categoryId;
  final String currencyCode;
  final double limit;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget copyWith({
    String? id,
    String? userId,
    String? name,
    String? categoryId,
    String? currencyCode,
    double? limit,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      currencyCode: currencyCode ?? this.currencyCode,
      limit: limit ?? this.limit,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Budget(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      currencyCode: (json['currencyCode'] as String? ?? 'USD').toUpperCase(),
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (json['updatedAt'] is Timestamp)
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    Timestamp? toTimestamp(DateTime? value) {
      return value != null ? Timestamp.fromDate(value) : null;
    }

    return {
      'id': id,
      'userId': userId,
      'name': name,
      'categoryId': categoryId,
      'currencyCode': currencyCode.toUpperCase(),
      'limit': limit,
      'notes': notes,
      'startDate': toTimestamp(startDate),
      'endDate': toTimestamp(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
