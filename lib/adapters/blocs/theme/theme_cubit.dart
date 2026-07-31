import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/ports/settings_repository.dart';

/// Holds the appearance choice and writes it through on every change.
class ThemeCubit extends Cubit<ThemePreference> {
  ThemeCubit(this._settings, {ThemePreference initial = ThemePreference.system})
      : super(initial);

  final SettingsRepository _settings;

  /// Selects [preference] and persists it.
  Future<void> select(ThemePreference preference) async {
    if (preference == state) return;
    emit(preference);
    await _settings.writeThemePreference(preference);
  }
}
