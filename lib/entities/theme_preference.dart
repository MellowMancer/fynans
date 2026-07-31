/// What the user chose in the appearance toggle.
///
/// Deliberately not Flutter's `ThemeMode`: this is an entity, so it must not
/// depend on the framework. The UI maps it to a `ThemeMode` at the edge.
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

  /// The form written to storage. The enum name, so the stored value stays
  /// readable and survives reordering.
  String get storageValue => name;
}
