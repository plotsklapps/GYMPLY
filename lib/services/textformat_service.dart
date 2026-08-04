// Extension to easily format Strings. Will be used more.
extension StringFormatter on String {
  // Capitalize first letter of String: "strength" -> "Strength"
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  // Convert entire String to uppercase: "cardio" -> "CARDIO"
  String capitalizeAll() {
    return toUpperCase();
  }

  // Convert entire String to lowercase: "Stretch" -> "stretch"
  String lowercaseAll() {
    return toLowerCase();
  }

  // Check if string is a valid http or https URL.
  bool get isValidHttpUrl {
    final String trimmed = trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}

// Helper function accepting nullable String.
bool isValidHttpUrl(String? url) {
  if (url == null) return false;
  return url.isValidHttpUrl;
}
