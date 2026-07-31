import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';

/// Icon + palette slot for each known tag.
///
/// The colour is stored as an *index* into [AppColors.categorical], not as a
/// literal: the scale differs between light and dark, so a tag's colour can
/// only be resolved once the active theme is known. Icon and slot live together
/// so the two cannot drift apart.
class _TagStyle {
  const _TagStyle(this.icon, this.slot);

  final IconData icon;

  /// Index into [AppColors.categorical], or [TagHelper.mutedSlot].
  final int slot;
}

abstract final class TagHelper {
  /// Slot for tags that should read as "no particular category".
  static const int mutedSlot = -1;

  static const Map<String, _TagStyle> _styles = <String, _TagStyle>{
    'food': _TagStyle(Icons.restaurant, 0),
    'groceries': _TagStyle(Icons.local_grocery_store, 1),
    'transport': _TagStyle(Icons.directions_bus_filled, 2),
    'shopping': _TagStyle(Icons.shopping_bag, 3),
    'bills': _TagStyle(Icons.receipt_long, 4),
    'health': _TagStyle(Icons.favorite_border, 8),
    'travel': _TagStyle(Icons.flight_takeoff, 5),
    'entertainment': _TagStyle(Icons.local_activity, 6),
    'work': _TagStyle(Icons.work_outline, 7),
    'others': _TagStyle(Icons.more_horiz, mutedSlot),
  };

  static const IconData _fallbackIcon = Icons.label_outline;

  /// Every tag the picker offers, alphabetically.
  static List<String> getAllTags() => _styles.keys.toList()..sort();

  static IconData getIconForTag(String tag) =>
      _styles[_normalize(tag)]?.icon ?? _fallbackIcon;

  /// The tag's colour in the active theme.
  static Color colorForTag(AppColors colors, String tag) {
    final slot = _styles[_normalize(tag)]?.slot ?? _fallbackSlot(tag);
    if (slot == mutedSlot) return colors.inkMuted;
    return colors.categorical[slot % colors.categorical.length];
  }

  static String _normalize(String tag) => tag.toLowerCase().trim();

  /// Unknown tags still get a stable slot rather than a flat grey, so
  /// user-created tags remain distinguishable.
  static int _fallbackSlot(String tag) {
    final key = _normalize(tag);
    if (key.isEmpty) return mutedSlot;
    return key.codeUnits.fold<int>(0, (sum, c) => sum + c);
  }
}

/// `context.tagColor('food')` — the tag's colour in the active theme.
extension TagColorX on BuildContext {
  Color tagColor(String tag) => TagHelper.colorForTag(colors, tag);
}
