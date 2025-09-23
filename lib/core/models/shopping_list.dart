import 'package:cloud_firestore/cloud_firestore.dart';

enum ShoppingListType { grocery, shopping }

class ShoppingList {
  ShoppingList({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.type = ShoppingListType.grocery,
    this.notes,
    this.currency = 'USD',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String userId;
  final String name;
  final ShoppingListType type;
  final String? notes;
  final String currency;
  final DateTime createdAt;

  ShoppingList copyWith({
    String? id,
    String? userId,
    String? name,
    ShoppingListType? type,
    String? notes,
    String? currency,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    ShoppingListType parseType(String? raw) {
      if (raw == null) return ShoppingListType.grocery;
      return ShoppingListType.values.firstWhere(
        (value) => value.name.toUpperCase() == raw.toUpperCase(),
        orElse: () => ShoppingListType.grocery,
      );
    }

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ShoppingList(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: parseType(json['type'] as String?),
      notes: json['notes'] as String?,
      currency: (json['currency'] as String? ?? 'USD').toUpperCase(),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name.toUpperCase(),
      'notes': notes,
      'currency': currency.toUpperCase(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
