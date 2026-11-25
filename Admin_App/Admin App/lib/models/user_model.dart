class UserModel {
  final int id;
  final String name;
  final String phone;
  final int? age;
  final String? gender;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.age,
    this.gender,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      age: json['age'],
      gender: json['gender'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'age': age,
      'gender': gender,
    };
  }
}
