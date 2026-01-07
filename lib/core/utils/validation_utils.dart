/// String validation utilities
class ValidationUtils {
  /// Validate license plate format (Vietnam)
  static bool isValidLicensePlate(String plate) {
    // Format: 51A-12345, 51A-123.45, 30H-12345
    final regex = RegExp(r'^[0-9]{2}[A-Z]{1,2}[-\s]?[0-9]{3,5}\.?[0-9]{0,2}$');
    return regex.hasMatch(plate.toUpperCase().trim());
  }

  /// Validate phone number (Vietnam)
  static bool isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    return regex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Validate email
  static bool isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email);
  }

  /// Validate not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate weight range
  static bool isValidWeight(double weight, {double min = 0, double max = 100000}) {
    return weight >= min && weight <= max;
  }

  /// Sanitize license plate
  static String sanitizeLicensePlate(String plate) {
    return plate.toUpperCase().replaceAll(RegExp(r'[\s]'), '').trim();
  }
}
