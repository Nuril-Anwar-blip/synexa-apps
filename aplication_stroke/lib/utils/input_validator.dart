/// Kelas utilitas untuk validasi input form (Email, Password, No. HP).
class InputValidator {
  const InputValidator._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? _isEmpty(String? value, String field) {
    if (value == null || value.isEmpty) {
      return "$field tidak boleh kosong";
    }
    return null;
  }

  /// Validasi apakah input kosong atau tidak.
  static String? empty(String? value, String field) {
    return _isEmpty(value, field);
  }

  /// Validasi format email menggunakan Regex.
  static String? email(String? value) {
    final emptyCheck = _isEmpty(value, "Email");
    if (emptyCheck != null) return emptyCheck;

    if (!_emailRegExp.hasMatch(value!)) {
      return "Format email tidak valid";
    }
    return null;
  }

  /// Validasi panjang minimal karakter.
  static String? minLength(String? value, String field, int length) {
    final emptyCheck = _isEmpty(value, field);
    if (emptyCheck != null) return emptyCheck;

    if (value!.length < length) {
      return "$field harus memiliki minimal $length karakter.";
    }
    return null;
  }

  /// Validasi nomor telepon (harus diawali 08 atau +62 dan minimal 9 digit).
  static String? phoneNumber(String? value) {
    final emptyCheck = _isEmpty(value, "Nomor Telepon");
    if (emptyCheck != null) return emptyCheck;
    final trimValue = value!.trim().toLowerCase();

    if (!trimValue.startsWith('08') && !trimValue.startsWith('+62')) {
      return "Nomor telepone harus diawali dengan '08' atau '+62'.";
    }
    if (trimValue.length < 9) {
      return "Nomor telepon minimal 9 digit.";
    }
    return null;
  }
}

