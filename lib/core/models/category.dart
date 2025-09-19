class Category {
  const Category({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.iconName = '',
    this.color = '',
    this.parentCategoryId,
  });

  final String id;
  final String userId;
  final String name;
  final String iconName;
  final String color;
  final String? parentCategoryId;

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? iconName,
    String? color,
    String? parentCategoryId,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconName: json['iconName'] as String? ?? '',
      color: json['color'] as String? ?? '',
      parentCategoryId: json['parentCategoryId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'iconName': iconName,
      'color': color,
      'parentCategoryId': parentCategoryId,
    };
  }
}
