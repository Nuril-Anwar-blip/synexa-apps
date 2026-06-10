import 'dart:convert';
import 'emergency_contact_model.dart'; // Pastikan path ini benar

class UserModel {
  final String? id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final int age;
  final double height;
  final double weight;
  final String gender;
  final String phoneNumber;
  final List<String> medicalHistory;
  final List<String> drugAllergy;
  final EmergencyContactModel emergencyContact;

  UserModel({
    this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.phoneNumber,
    required this.medicalHistory,
    required this.drugAllergy,
    required this.emergencyContact,
  });

  // Fungsi untuk membuat objek UserModel dari data map (misal: dari Supabase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String?,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      age: map['age'] as int? ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      gender: map['gender'] as String? ?? 'male',
      phoneNumber: map['phone_number'] as String? ?? '',
      // Menangani data jsonb/array dari Supabase dengan aman
      medicalHistory: map['medical_history'] != null
          ? List<String>.from(map['medical_history'])
          : [],
      drugAllergy: map['drug_allergy'] != null
          ? List<String>.from(map['drug_allergy'])
          : [],
      emergencyContact: map['emergency_contact'] != null
          ? EmergencyContactModel.fromMap(
              map['emergency_contact'],
            ) // Baris ini sekarang akan valid
          : EmergencyContactModel(name: '', phoneNumber: '', relationship: ''),
    );
  }

  // Fungsi untuk mengubah objek UserModel menjadi map untuk dikirim ke Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'photo_url': photoUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'phone_number': phoneNumber,
      'medical_history': medicalHistory,
      'drug_allergy': drugAllergy,
      'emergency_contact': emergencyContact.toMap(),
    };
  }

  // Fungsi untuk membuat salinan objek dengan beberapa nilai yang diperbarui
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? phoneNumber,
    List<String>? medicalHistory,
    List<String>? drugAllergy,
    EmergencyContactModel? emergencyContact,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      drugAllergy: drugAllergy ?? this.drugAllergy,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
