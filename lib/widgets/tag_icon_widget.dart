import 'package:flutter/material.dart';
import 'package:fynans/utils/tag_helper.dart';

class TagIconWidget extends StatelessWidget {
  final List<String> tags;
  final double size;

  const TagIconWidget({
    super.key,
    required this.tags,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade800,
        child: Icon(Icons.label_outline, size: size * 0.6, color: Colors.white70),
      );
    }

    if (tags.length == 1) {
      final tag = tags.first;
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: TagHelper.getColorForTag(tag).withAlpha(85),
        child: Icon(
          TagHelper.getIconForTag(tag),
          size: size * 0.6,
          color: TagHelper.getColorForTag(tag),
        ),
      );
    }

    // For 2 or more tags, show a split icon
    final tag1 = tags[0];
    final tag2 = tags[1];

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          children: [
            // Left half
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Container(
                    width: size,
                    height: size,
                    color: TagHelper.getColorForTag(tag1).withAlpha(85),
                    child: Icon(TagHelper.getIconForTag(tag1), size: size * 0.5, color: TagHelper.getColorForTag(tag1)),
                  ),
                ),
              ),
            ),
            // Right half
            Align(
              alignment: Alignment.centerRight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 0.5,
                  child: Container(
                    width: size,
                    height: size,
                    color: TagHelper.getColorForTag(tag2).withAlpha(85),
                    child: Icon(TagHelper.getIconForTag(tag2), size: size * 0.5, color: TagHelper.getColorForTag(tag2)),
                  ),
                ),
              ),
            ),
            if (tags.length > 2)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                  child: Text('+${tags.length - 2}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}