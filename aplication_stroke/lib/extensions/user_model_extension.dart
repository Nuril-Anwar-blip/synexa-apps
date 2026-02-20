import '../models/user_model.dart';
import '../utils/util.dart';

/// Ekstensi untuk [UserModel] guna mempermudah tampilan UI.
extension UserModelUI on UserModel {
  /// Nama lengkap pengguna dengan format kapital di setiap awal kata.
  String get fullNameUI => capitalizeWords(fullName);

  /// Riwayat medis pengguna dalam bentuk string yang dipisahkan koma.
  String get medicalHistoryUI =>
      medicalHistory.map((e) => capitalizeWords(e)).join(', ');

  /// Alergi obat pengguna dalam bentuk string yang dipisahkan koma.
  String get drugAllergyUI =>
      drugAllergy.map((e) => capitalizeWords(e)).join(', ');

  /// Jenis kelamin pengguna dalam bahasa Indonesia (Pria/Wanita).
  String get genderUI => gender == "male" ? "Pria" : "Wanita";

  /// Nomor telepon yang diformat (misal: +62 812...).
  String get phoneNumberUI {
    if (phoneNumber.startsWith("+62")) {
      return "(+62) ${phoneNumber.substring(3)}";
    }
    return phoneNumber;
  }
}

