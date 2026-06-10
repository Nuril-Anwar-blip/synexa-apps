class EmergencyContactModel {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContactModel({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  // DIUBAH: Menerima Map<String, dynamic> agar lebih fleksibel
  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      // Menggunakan 'as String?' untuk penanganan tipe yang lebih aman
      name: map['name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
    );
  }

  // DIUBAH: Mengirim Map<String, dynamic>
  Map<String, dynamic> toMap() {
    // Normalisasi nomor telepon tetap di sini
    String normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.startsWith("08")) {
      normalizedPhone = "+62${normalizedPhone.substring(1)}";
    }

    return {
      'name': name,
      'phone_number': normalizedPhone,
      'relationship': relationship,
    };
  }

  // BARU: Metode 'copyWith' untuk membuat salinan objek dengan mudah
  EmergencyContactModel copyWith({
    String? name,
    String? phoneNumber,
    String? relationship,
  }) {
    return EmergencyContactModel(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
    );
  }

  // BARU: Override 'toString' untuk debugging yang lebih mudah
  @override
  String toString() =>
      'EmergencyContactModel(name: $name, phoneNumber: $phoneNumber, relationship: $relationship)';

  // BARU: Override 'hashCode' dan '==' untuk perbandingan objek yang benar
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is EmergencyContactModel &&
      other.name == name &&
      other.phoneNumber == phoneNumber &&
      other.relationship == relationship;
  }

  @override
  int get hashCode => name.hashCode ^ phoneNumber.hashCode ^ relationship.hashCode;
}