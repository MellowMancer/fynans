import 'package:flutter/material.dart';

class TagHelper {
  static final Map<String, IconData> _tagIcons = {
    'food': Icons.fastfood,
    'entertainment': Icons.movie,
    'transport': Icons.directions_car,
    'shopping': Icons.shopping_bag,
    'bills': Icons.receipt_long,
    'health': Icons.healing,
    'travel': Icons.flight,
    'groceries': Icons.local_grocery_store,
    'work': Icons.work,
    'pokemon': Icons.catching_pokemon,
    'others': Icons.more_horiz,
  };

  static final Map<String, Color> _tagColors = {
    'food': Colors.orange,
    'entertainment': Colors.purple,
    'transport': Colors.blue,
    'shopping': Colors.pink,
    'bills': Colors.red,
    'health': Colors.green,
    'travel': Colors.teal,
    'groceries': Colors.lightGreen,
    'work': Colors.indigo,
    'pokemon': Colors.yellow,
    'others': Colors.blueGrey,
  };

  static List<String> getAllTags() {
    return _tagIcons.keys.toList()..sort();
  }

  static IconData getIconForTag(String tag) {
    return _tagIcons[tag.toLowerCase().trim()] ?? Icons.label_outline;
  }

  static Color getColorForTag(String tag) {
    return _tagColors[tag.toLowerCase().trim()] ?? Colors.grey;
  }
}