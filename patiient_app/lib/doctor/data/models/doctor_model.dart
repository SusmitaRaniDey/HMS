import '../../config/environment.dart';

class DoctorModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String specialty;
  final String? degrees;
  final int? experience;
  final String? workingAt;
  final double? fee;
  final String? profilePic;
  final String? biography;
  final List<String>? languages;
  final List<String>? slots;
  final List<String>? availableSlots;
  final DateTime? createdAt;

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialty,
    this.degrees,
    this.experience,
    this.workingAt,
    this.fee,
    this.profilePic,
    this.biography,
    this.languages,
    this.slots,
    this.availableSlots,
    this.createdAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String,
      degrees: json['degrees'] as String?,
      experience: json['experience'] as int?,
      workingAt: json['working_at'] as String?,
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : null,
      profilePic: Environment.resolveMediaUrl(
        json['profilePic'] ?? json['profile_pic'],
      ),
      biography: json['biography'] as String?,
      languages: json['languages'] is List
          ? (json['languages'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
          : null,
      slots: json['slots'] is List
          ? (json['slots'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      availableSlots: json['available_slots'] is List
          ? (json['available_slots'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialty': specialty,
      'degrees': degrees,
      'experience': experience,
      'working_at': workingAt,
      'fee': fee,
      'profilePic': profilePic,
      'biography': biography,
      'languages': languages,
      'slots': slots,
      'available_slots': availableSlots,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Helper getters
  String get experienceText => experience != null ? '$experience years' : 'N/A';
  String get feeText => fee != null ? '৳${fee!.toStringAsFixed(0)}' : 'N/A';
}
