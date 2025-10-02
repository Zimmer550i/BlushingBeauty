class AllUserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String image;
  final String gender;
  final bool verified;

  AllUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.image,
    required this.gender,
    required this.verified,
  });

  factory AllUserModel.fromJson(Map<String, dynamic> json) {
    return AllUserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      image: json['image'] ?? '',
      gender: json['gender'] ?? '',
      verified: json['verified'] ?? false,
    );
  }
}
