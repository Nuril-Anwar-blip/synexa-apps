import '../models/emergency_contact_model.dart';
import '../utils/util.dart';

/// Ekstensi untuk [EmergencyContactModel] guna mempermudah tampilan UI.
extension EmergencyContactModelUI on EmergencyContactModel {
  /// Nama kontak darurat dengan format kapital di setiap awal kata.
  String get nameUI => capitalizeWords(name);
  /// Hubungan dengan pengguna dengan format kapital di setiap awal kata.
  String get relationshipUI => capitalizeWords(relationship);

  /// Nomor telepon yang diformat (misal: +62 812...).
  String get phoneNumberUI {
    if (phoneNumber.startsWith("+62")) {
      return "(+62) ${phoneNumber.substring(3)}";
    }
    return phoneNumber;
  }
}

