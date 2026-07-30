import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';

/// Icon + colour for each known tag.
///
/// Icon and colour are defined together so the two can never drift apart, and
/// the hues come from [AppColors.categorical] so tags sit inside the app's
/// warm palette instead of using saturated stock Material colours.
class _TagStyle {
  const _TagStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

abstract final class TagHelper {
  static final Map<String, _TagStyle> _styles = <String, _TagStyle>{
    'food': _TagStyle(Icons.restaurant, AppColors.categorical[0]),
    'groceries': _TagStyle(Icons.local_grocery_store, AppColors.categorical[1]),
    'transport': _TagStyle(Icons.directions_bus_filled, AppColors.categorical[2]),
    'shopping': _TagStyle(Icons.shopping_bag, AppColors.categorical[3]),
    'bills': _TagStyle(Icons.receipt_long, AppColors.categorical[4]),
    'health': _TagStyle(Icons.favorite_border, AppColors.danger),
    'travel': _TagStyle(Icons.flight_takeoff, AppColors.categorical[5]),
    'entertainment': _TagStyle(Icons.local_activity, AppColors.categorical[6]),
    'work': _TagStyle(Icons.work_outline, AppColors.categorical[7]),
    'others': _TagStyle(Icons.more_horiz, AppColors.inkMuted),
  };

  static const IconData _fallbackIcon = Icons.label_outline;

  /// Every tag the picker offers, alphabetically.
  static List<String> getAllTags() => _styles.keys.toList()..sort();

  static IconData getIconForTag(String tag) =>
      _styles[_normalize(tag)]?.icon ?? _fallbackIcon;

  static Color getColorForTag(String tag) =>
      _styles[_normalize(tag)]?.color ?? _fallbackColor(tag);

  static String _normalize(String tag) => tag.toLowerCase().trim();

  /// Unknown tags still get a stable colour from the palette rather than a
  /// flat grey, so user-created tags remain distinguishable.
  static Color _fallbackColor(String tag) {
    final key = _normalize(tag);
    if (key.isEmpty) return AppColors.inkMuted;
    final index = key.codeUnits.fold<int>(0, (sum, c) => sum + c) %
        AppColors.categorical.length;
    return AppColors.categorical[index];
  }
}
