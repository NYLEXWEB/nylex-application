class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profilePhoto;
  final bool isActive;
  final String? lastLoginAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePhoto,
    this.isActive = true,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'PARTNER',
      profilePhoto: json['profilePhoto'],
      isActive: json['isActive'] ?? true,
      lastLoginAt: json['lastLoginAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePhoto': profilePhoto,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt,
    };
  }
}
