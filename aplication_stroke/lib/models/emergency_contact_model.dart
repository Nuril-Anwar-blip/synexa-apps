// Lokasi: models/emergency_contact_model.dart

/// Model untuk menyimpan data kontak darurat pengguna.
class EmergencyContactModel {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContactModel({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  /// Membuat instance [EmergencyContactModel] dari Map (biasanya dari Supabase).
  // Menerima Map<String, dynamic> dari Supabase
  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      name: map['name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
    );
  }

  /// Mengubah instance menjadi Map untuk dikirim ke Supabase.
  // Mengirim Map<String, dynamic> ke Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
    };
  }
}

