extension StringFormatter on String {
  /// Capitalizes the first letter of the string.
  /// Example: "strength" -> "Strength"
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Converts the entire string to uppercase.
  /// Example: "cardio" -> "CARDIO"
  String capitalizeAll() {
    return toUpperCase();
  }

  /// Converts the entire string to lowercase.
  /// Example: "Stretch" -> "stretch"
  String lowercaseAll() {
    return toLowerCase();
  }
}
