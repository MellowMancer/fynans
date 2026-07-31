import 'package:fynans/entities/theme_preference.dart';

/// Abstract seam for small, device-local user settings.
abstract class SettingsRepository {
  /// The stored appearance choice, or [ThemePreference.system] if never set.
  Future<ThemePreference> readThemePreference();

  Future<void> writeThemePreference(ThemePreference preference);
}
