class PlateValidator {
  static final RegExp _moroccanRegex = RegExp(
    r'^[0-9]{1,5}[A-Z]{1,3}[0-9]{1,2}$',
    caseSensitive: false,
  );

  static bool isValidMoroccanPlate(String text) {
    final normalized = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return _moroccanRegex.hasMatch(normalized) && normalized.length >= 4;
  }

  static String normalizePlate(String plate) {
    return plate.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }
}