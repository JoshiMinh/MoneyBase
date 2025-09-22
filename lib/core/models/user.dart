class MoneyBaseUser {
  MoneyBaseUser({
    this.id = '',
    this.displayName = '',
    this.email = '',
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.premium = false,
    this.profilePictureUrl = '',
    this.photoUrl,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastLoginAt = lastLoginAt ?? DateTime.now();

  final String id;
  final String displayName;
  final String email;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool premium;
  final String profilePictureUrl;
  final String? photoUrl;

  MoneyBaseUser copyWith({
    String? id,
    String? displayName,
    String? email,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? premium,
    String? profilePictureUrl,
    String? photoUrl,
  }) {
    return MoneyBaseUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      premium: premium ?? this.premium,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory MoneyBaseUser.fromJson(Map<String, dynamic> json) {
    return MoneyBaseUser(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastLoginAt:
          DateTime.tryParse(json['lastLoginAt'] as String? ?? '') ??
          DateTime.now(),
      premium: json['premium'] as bool? ?? false,
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
    'premium': premium,
    'profilePictureUrl': profilePictureUrl,
    'photoUrl': photoUrl,
  };
}
