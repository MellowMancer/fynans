import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/tag_helper.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// Rounded-square avatar for a transaction's tags: the leading tag's glyph on a
/// tint of its own colour, with a `+n` badge when there are more.
class TagIconWidget extends StatelessWidget {
  const TagIconWidget({
    super.key,
    required this.tags,
    this.size = 40.0,
  });

  final List<String> tags;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasTags = tags.isNotEmpty;
    final color =
        hasTags ? context.tagColor(tags.first) : context.colors.inkMuted;
    final icon = hasTags
        ? TagHelper.getIconForTag(tags.first)
        : Icons.label_outline;
    final overflow = tags.length - 1;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(icon, size: size * 0.5, color: color),
          ),
          if (overflow > 0)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(color: context.colors.border),
                ),
                child: MonoText(
                  '+$overflow',
                  style: context.type.monoSmall.copyWith(fontSize: 9.5),
                  color: context.colors.inkSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
