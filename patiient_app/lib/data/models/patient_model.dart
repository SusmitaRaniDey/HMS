class PatientModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final DateTime? createdAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  PatientModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    DateTime? createdAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}