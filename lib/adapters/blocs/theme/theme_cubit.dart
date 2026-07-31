import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/ports/settings_repository.dart';

/// Holds the appearance choice and writes it through on every change.
///
/// Seeded with the already-loaded value so the first frame paints in the right
/// theme; reading the store here instead would flash the wrong one.
class ThemeCubit extends Cubit<ThemePreference> {
  ThemeCubit(this._settings, {ThemePreference initial = ThemePreference.system})
      : super(initial);

  final SettingsRepository _settings;

  /// Selects [preference] and persists it. The emit is not gated on the write:
  /// the UI should not wait on disk to repaint.
  Future<void> select(ThemePreference preference) async {
    if (preference == state) return;
    emit(preference);
    await _settings.writeThemePreference(preference);
  }
}
