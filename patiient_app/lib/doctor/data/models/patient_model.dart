class PatientModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final DateTime? createdAt;

  PatientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
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
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get contactInfo => email ?? phone ?? 'No contact';
}