class Validators {
  static String? required(String? value, [String message = "This field is required"]) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!regex.hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    if (value.trim().length < 7) {
      return "Enter a valid phone number";
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = "Amount"]) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    final numVal = double.tryParse(value.trim());
    if (numVal == null || numVal < 0) {
      return "Enter a valid positive number";
    }
    return null;
  }
}
