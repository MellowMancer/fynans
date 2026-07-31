/// What the user chose in the appearance toggle.
enum ThemePreference {
  /// Follow the device setting.
  system,
  light,
  dark;

  /// Parses a stored value, falling back to [system] for anything unknown —
  /// including a value written by a future version of the app.
  static ThemePreference fromStorage(String? value) {
    return ThemePreference.values.firstWhere(
      (preference) => preference.name == value,
      orElse: () => ThemePreference.system,
    );
  }

  /// The form written to storage.
  String get storageValue => name;
}
