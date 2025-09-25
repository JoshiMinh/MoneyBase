import 'package:cloud_firestore/cloud_firestore.dart';

enum BudgetPeriod { day, week, month, year, custom }

enum BudgetFlowType { expenses, income, both }

class Budget {
  Budget({
    this.id = '',
    this.userId = '',
    this.name = '',
    List<String>? categoryIds,
    this.currencyCode = 'USD',
    this.limit = 0.0,
    this.notes,
    this.period = BudgetPeriod.month,
    this.flowType = BudgetFlowType.expenses,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : categoryIds = List.unmodifiable(categoryIds ?? const <String>[]),
        startDate = startDate,
        endDate = endDate,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String name;
  final List<String> categoryIds;
  final String currencyCode;
  final double limit;
  final String? notes;
  final BudgetPeriod period;
  final BudgetFlowType flowType;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? categoryIds,
    String? currencyCode,
    double? limit,
    String? notes,
    BudgetPeriod? period,
    BudgetFlowType? flowType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      categoryIds: categoryIds != null
          ? List<String>.from(categoryIds)
          : List<String>.from(this.categoryIds),
      currencyCode: currencyCode ?? this.currencyCode,
      limit: limit ?? this.limit,
      notes: notes ?? this.notes,
      period: period ?? this.period,
      flowType: flowType ?? this.flowType,
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

    BudgetPeriod parsePeriod(String? value, DateTime? start, DateTime? end) {
      switch (value) {
        case 'day':
          return BudgetPeriod.day;
        case 'week':
          return BudgetPeriod.week;
        case 'year':
          return BudgetPeriod.year;
        case 'custom':
          return BudgetPeriod.custom;
        case 'month':
          return BudgetPeriod.month;
        default:
          return (start != null || end != null) ? BudgetPeriod.custom : BudgetPeriod.month;
      }
    }

    BudgetFlowType parseFlowType(String? value) {
      switch (value) {
        case 'income':
          return BudgetFlowType.income;
        case 'both':
          return BudgetFlowType.both;
        case 'expenses':
        default:
          return BudgetFlowType.expenses;
      }
    }

    final rawCategoryIds = (json['categoryIds'] as List<dynamic>?)
            ?.map((dynamic item) => item as String?)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList() ??
        <String>[];

    if (rawCategoryIds.isEmpty) {
      final legacyCategoryId = json['categoryId'] as String?;
      if (legacyCategoryId != null && legacyCategoryId.isNotEmpty) {
        rawCategoryIds.add(legacyCategoryId);
      }
    }

    final start = parseDate(json['startDate']);
    final end = parseDate(json['endDate']);

    return Budget(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryIds: rawCategoryIds,
      currencyCode: (json['currencyCode'] as String? ?? 'USD').toUpperCase(),
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      period: parsePeriod(json['period'] as String?, start, end),
      flowType: parseFlowType(json['flowType'] as String?),
      startDate: start,
      endDate: end,
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
      'categoryIds': categoryIds,
      'currencyCode': currencyCode.toUpperCase(),
      'limit': limit,
      'notes': notes,
      'period': period.name,
      'flowType': flowType.name,
      'startDate': toTimestamp(startDate),
      'endDate': toTimestamp(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
