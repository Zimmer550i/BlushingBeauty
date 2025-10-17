class User {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? image;
  final String? gender;
  final DateTime? dob;
  final bool? isDeleted;
  final bool? verified;
  final bool? isFirstLogin;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.image,
    this.gender,
    this.dob,
    this.isDeleted,
    this.verified,
    this.isFirstLogin,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  /// Map JSON → User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["_id"] as String?,
      name: json["name"] as String?,
      email: json["email"] as String?,
      phone: json["phone"] as String?,
      role: json["role"] as String?,
      image: json["image"] as String?,
      gender: json["gender"] as String?,
      dob: json["dob"] as DateTime?,
      isDeleted: json["isDeleted"] as bool?,
      verified: json["verified"] as bool?,
      isFirstLogin: json["isFirstLogin"] as bool?,
      createdAt: json["createdAt"]?.toString(),
      updatedAt: json["updatedAt"]?.toString(),
      v: json["__v"] as int?,
    );
  }

  /// Map User → JSON
  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "image": image,
      "gender": gender,
      "dob": dob,
      "isDeleted": isDeleted,
      "verified": verified,
      "isFirstLogin": isFirstLogin,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "__v": v,
    };
  }
}
