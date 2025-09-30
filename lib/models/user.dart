class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String image;
  final String role;
  final String gender;
  final DateTime? dob;
  final bool isDeleted;
  final bool verified;
  final bool isFirstLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
    required this.role,
    required this.gender,
    this.dob,
    required this.isDeleted,
    required this.verified,
    required this.isFirstLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  // From JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'] ?? '',
      role: json['role'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      isDeleted: json['isDeleted'] ?? false,
      verified: json['verified'] ?? false,
      isFirstLogin: json['isFirstLogin'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      version: json['__v'] ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
      'role': role,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'isDeleted': isDeleted,
      'verified': verified,
      'isFirstLogin': isFirstLogin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }
}
