import 'package:cloud_firestore/cloud_firestore.dart';

enum ShoppingItemPriority { low, medium, high }

class ShoppingItem {
  ShoppingItem({
    this.id = '',
    this.userId = '',
    this.listId = '',
    this.title = '',
    this.bought = false,
    this.priority = ShoppingItemPriority.medium,
    this.price = 0.0,
    this.currency = 'USD',
    this.iconEmoji,
    this.iconUrl,
    this.parentItemRef,
    this.subItemRefs = const <DocumentReference<Object?>>[],
    DateTime? purchaseDate,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : purchaseDate = purchaseDate,
        expiryDate = expiryDate,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String listId;
  final String title;
  final bool bought;
  final ShoppingItemPriority priority;
  final double price;
  final String currency;
  final String? iconEmoji;
  final String? iconUrl;
  final DocumentReference<Object?>? parentItemRef;
  final List<DocumentReference<Object?>> subItemRefs;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItem copyWith({
    String? id,
    String? userId,
    String? listId,
    String? title,
    bool? bought,
    ShoppingItemPriority? priority,
    double? price,
    String? currency,
    String? iconEmoji,
    String? iconUrl,
    DocumentReference<Object?>? parentItemRef,
    List<DocumentReference<Object?>>? subItemRefs,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      bought: bought ?? this.bought,
      priority: priority ?? this.priority,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      iconUrl: iconUrl ?? this.iconUrl,
      parentItemRef: parentItemRef ?? this.parentItemRef,
      subItemRefs: subItemRefs ?? this.subItemRefs,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    ShoppingItemPriority parsePriority(String? raw) {
      if (raw == null) return ShoppingItemPriority.medium;
      return ShoppingItemPriority.values.firstWhere(
        (value) => value.name.toUpperCase() == raw.toUpperCase(),
        orElse: () => ShoppingItemPriority.medium,
      );
    }

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    List<DocumentReference<Object?>> parseRefs(dynamic value) {
      if (value is List) {
        return value
            .where((element) => element is DocumentReference)
            .map((element) => element as DocumentReference<Object?>)
            .toList(growable: false);
      }
      return const [];
    }

    return ShoppingItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      listId: json['listId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      bought: json['bought'] as bool? ?? false,
      priority: parsePriority(json['priority'] as String?),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String? ?? 'USD').toUpperCase(),
      iconEmoji: json['icon'] is Map<String, dynamic>
          ? (json['icon']['emoji'] as String?)
          : null,
      iconUrl: json['icon'] is Map<String, dynamic>
          ? (json['icon']['url'] as String?)
          : null,
      parentItemRef: json['relations'] is Map<String, dynamic>
          ? json['relations']['parentItemRef'] as DocumentReference<Object?>?
          : null,
      subItemRefs: json['relations'] is Map<String, dynamic>
          ? parseRefs(json['relations']['subItemRefs'])
          : const [],
      purchaseDate: json['dates'] is Map<String, dynamic>
          ? parseDate(json['dates']['purchaseDate'])
          : null,
      expiryDate: json['dates'] is Map<String, dynamic>
          ? parseDate(json['dates']['expiryDate'])
          : null,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (json['updatedAt'] is Timestamp)
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> buildIcon() {
      return {
        'emoji': iconEmoji,
        'url': iconUrl,
      };
    }

    Map<String, dynamic> buildDates() {
      return {
        'purchaseDate':
            purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
        'expiryDate':
            expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      };
    }

    Map<String, dynamic> buildRelations() {
      return {
        'parentItemRef': parentItemRef,
        'subItemRefs': subItemRefs,
      };
    }

    return {
      'id': id,
      'userId': userId,
      'listId': listId,
      'title': title,
      'bought': bought,
      'priority': priority.name.toUpperCase(),
      'price': price,
      'currency': currency.toUpperCase(),
      'icon': buildIcon(),
      'dates': buildDates(),
      'relations': buildRelations(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
