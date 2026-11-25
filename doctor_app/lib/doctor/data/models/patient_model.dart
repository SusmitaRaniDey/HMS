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
      id: _parseId(json['id']),
      name: json['name'] as String? ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
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