class Validators {
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN wajib diisi';
    }
    if (value.length < 4) {
      return 'PIN minimal 4 digit';
    }
    if (value.length > 6) {
      return 'PIN maksimal 6 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN harus angka';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? validateMenuName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama menu wajib diisi';
    }
    if (value.length > 100) {
      return 'Nama menu maksimal 100 karakter';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harga wajib diisi';
    }
    final price = int.tryParse(value);
    if (price == null) {
      return 'Harga harus angka';
    }
    if (price < 0) {
      return 'Harga tidak boleh negatif';
    }
    if (price > 100000000) {
      return 'Harga maksimal Rp 100.000.000';
    }
    return null;
  }
}
