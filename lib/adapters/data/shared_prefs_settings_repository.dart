import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/ports/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SettingsRepository] backed by `SharedPreferences`.
class SharedPrefsSettingsRepository implements SettingsRepository {
  static const String _themeKey = 'theme_preference';

  @override
  Future<ThemePreference> readThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemePreference.fromStorage(prefs.getString(_themeKey));
  }

  @override
  Future<void> writeThemePreference(ThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, preference.storageValue);
  }
}
