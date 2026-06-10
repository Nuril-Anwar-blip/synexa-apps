/// ====================================================================
/// File: user_model.dart
/// --------------------------------------------------------------------
/// Model Data Pengguna (User Model)
/// 
/// Dokumen ini mendefinisikan struktur data pengguna yang digunakan
/// di seluruh aplikasi Synexa.
/// 
/// Properties:
/// - id: ID unik pengguna (UUID dari Supabase)
/// - email: Alamat email pengguna
/// - fullName: Nama lengkap pengguna
/// - birthDate: Tanggal lahir
/// - height: Tinggi badan (cm)
/// - weight: Berat badan (kg)
/// - gender: Jenis kelamin
/// - phoneNumber: Nomor telepon
/// - medicalHistory: Riwayat penyakit
/// - drugAllergy: Alergi obat
/// - emergencyContacts: Daftar kontak darurat
/// - role: Peran (pasien/apoteker/dokter)
/// - photoUrl: URL foto profil
/// 
/// Author: Tim Developer Synexa
/// ====================================================================

import 'dart:convert';
import 'emergency_contact_model.dart';

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

    String _mapRoleFromDb(String? dbRole) {
      switch (dbRole) {
        case 'patient':
          return 'pasien';
        case 'pharmacist':
          return 'apoteker';
        case 'admin':
          return 'admin';
        default:
          return dbRole ?? 'pasien';
      }
    }

    return UserModel(
      id: map['id'] as String?,
      email: map['email'] as String? ?? '',
      fullName:
          map['full_name'] as String? ?? map['name'] as String? ?? '',
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'].toString())
          : map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'].toString())
          : null,
      height:
          (map['height'] as num?)?.toDouble() ??
          (map['height_cm'] as num?)?.toDouble() ??
          0.0,
      weight:
          (map['weight'] as num?)?.toDouble() ??
          (map['weight_kg'] as num?)?.toDouble() ??
          0.0,
      gender: map['gender'] as String? ?? 'male',
      phoneNumber:
          map['phone_number'] as String? ?? map['phone'] as String? ?? '',
      role: _mapRoleFromDb(map['role'] as String?),

      // Menggunakan fungsi bantuan yang aman
      medicalHistory: _parseListFromMap(map['medical_history']),
      drugAllergy: _parseListFromMap(map['drug_allergy']),

      emergencyContacts: () {
        if (map['emergency_contact'] is List) {
          return (map['emergency_contact'] as List)
              .map(
                (e) => EmergencyContactModel.fromMap(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        final ecName = map['emergency_contact_name']?.toString();
        final ecPhone = map['emergency_contact_phone']?.toString();
        if (ecName != null && ecName.isNotEmpty) {
          return [
            EmergencyContactModel(
              name: ecName,
              phoneNumber: ecPhone ?? '',
              relationship: '',
            ),
          ];
        }
        return <EmergencyContactModel>[];
      }(),

      photoUrl:
          map['photo_url'] as String? ?? map['profile_picture'] as String?,
    );
  }

  static String _mapRoleToDb(String role) {
    switch (role) {
      case 'pasien':
        return 'patient';
      case 'apoteker':
        return 'pharmacist';
      default:
        return role;
    }
  }

  /// Map untuk insert ke `public.users` (schema smart_stroke).
  Map<String, dynamic> toSupabaseInsertMap({required String authId}) {
    final emergency = emergencyContacts.isNotEmpty
        ? emergencyContacts.first
        : null;

    return {
      'auth_id': authId,
      'email': email,
      'name': fullName,
      'phone': phoneNumber,
      if (birthDate != null)
        'date_of_birth': birthDate!.toIso8601String().split('T').first,
      'gender': gender,
      if (height > 0) 'height_cm': height,
      if (weight > 0) 'weight_kg': weight,
      'role': _mapRoleToDb(role),
      if (photoUrl != null) 'profile_picture': photoUrl,
      if (emergency != null) ...{
        'emergency_contact_name': emergency.name,
        'emergency_contact_phone': emergency.phoneNumber,
      },
    };
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

