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
}
