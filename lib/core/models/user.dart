enum UserRole { user, pic, admin }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final UserRole role;
  final String? profilePicture;
  final String? areaId;
  final bool isOnline;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? whatsappVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.role,
    this.profilePicture,
    this.areaId,
    this.isOnline = false,
    this.isActive = true,
    this.emailVerifiedAt,
    this.whatsappVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      city: json['city'],
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'].toLowerCase(),
        orElse: () => UserRole.user,
      ),
      profilePicture: json['profile_picture'],
      areaId: json['area_id'],
      isOnline: json['is_online'] ?? false,
      isActive: json['is_active'] ?? true,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      whatsappVerifiedAt: json['whatsapp_verified_at'] != null
          ? DateTime.parse(json['whatsapp_verified_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'role': role.name,
      'profile_picture': profilePicture,
      'area_id': areaId,
      'is_online': isOnline,
      'is_active': isActive,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'whatsapp_verified_at': whatsappVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? city,
    UserRole? role,
    String? profilePicture,
    String? areaId,
    bool? isOnline,
    bool? isActive,
    DateTime? emailVerifiedAt,
    DateTime? whatsappVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      areaId: areaId ?? this.areaId,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      whatsappVerifiedAt: whatsappVerifiedAt ?? this.whatsappVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
