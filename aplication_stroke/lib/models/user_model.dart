import 'dart:convert';
import 'emergency_contact_model.dart'; // Pastikan path import ini benar

/// Model utama untuk data profil pengguna.
class UserModel {
  final String? id;
  final String email;
  final String fullName;
  final DateTime? birthDate;
  final double height;
  final double weight;
  final String gender;
  final String phoneNumber;
  final List<String> medicalHistory;
  final List<String> drugAllergy;
  final List<EmergencyContactModel> emergencyContacts;
  final String role;
  final String? photoUrl;

  UserModel({
    this.id,
    required this.email,
    required this.fullName,
    this.birthDate,
    required this.height,
    required this.weight,
    required this.gender,
    required this.phoneNumber,
    required this.medicalHistory,
    required this.drugAllergy,
    required this.emergencyContacts,
    this.role = 'pasien',
    this.photoUrl,
  });

  /// Membuat instance [UserModel] dari Map data Supabase.
  /// Menangani parsing list yang mungkin berupa String JSON atau List asli.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Fungsi bantuan untuk parsing yang lebih aman
    List<String> _parseListFromMap(dynamic data) {
      if (data == null) return [];
      // Jika data adalah String (format lama), decode dulu
      if (data is String) {
        if (data.isEmpty) return [];
        final decoded = jsonDecode(data);
        return List<String>.from(decoded);
      }
      // Jika data sudah List (format baru), langsung gunakan
      if (data is List) {
        return List<String>.from(data);
      }
      return [];
    }

    return UserModel(
      id: map['id'] as String?,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      birthDate: map['birth_date'] != null ? DateTime.tryParse(map['birth_date']) : null,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      gender: map['gender'] as String? ?? 'male',
      phoneNumber: map['phone_number'] as String? ?? '',
      role: map['role'] as String? ?? 'pasien',

      // Menggunakan fungsi bantuan yang aman
      medicalHistory: _parseListFromMap(map['medical_history']),
      drugAllergy: _parseListFromMap(map['drug_allergy']),

      emergencyContacts:
          map['emergency_contact'] != null && map['emergency_contact'] is List
          ? (map['emergency_contact'] as List).map((e) => EmergencyContactModel.fromMap(e as Map<String, dynamic>)).toList()
          : [],

      photoUrl: map['photo_url'] as String?,
    );
  }

  /// Mengubah instance menjadi Map untuk disimpan ke Supabase.
  /// Memastikan format data sesuai dengan tipe kolom di database (misal: jsonb).
  // Mengirim data ke Supabase dengan format yang benar untuk `jsonb`
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'birth_date': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'gender': gender,
      'phone_number': phoneNumber,
      'role': role,
      'photo_url': photoUrl, // Penting: photoUrl sudah dimasukkan
      // Kirim sebagai List<String> asli, BUKAN string JSON
      'medical_history': medicalHistory,
      'drug_allergy': drugAllergy,

      // Kirim sebagai List of Maps
      'emergency_contact': emergencyContacts.map((e) => e.toMap()).toList(),
    };
  }

  /// Membuat salinan objek [UserModel] dengan perubahan pada properti tertentu.
  // Fungsi copyWith untuk kemudahan modifikasi objek
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? gender,
    String? phoneNumber,
    String? role,
    List<String>? medicalHistory,
    List<String>? drugAllergy,
    List<EmergencyContactModel>? emergencyContacts,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      drugAllergy: drugAllergy ?? this.drugAllergy,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

