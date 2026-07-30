import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/app_labels.dart';

/// The one container primitive. Everything panel-shaped in the app is an
/// [AppCard] — eyebrow label, optional title row with a trailing action, and a
/// body — so no screen re-rolls its own `Container` + `BoxDecoration`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.label,
    this.title,
    this.trailing,
    this.padding,
    this.margin,
    this.background,
    this.borderRadius,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Body content, below the optional header.
  final Widget? child;

  /// Mono uppercase eyebrow, e.g. `STATEMENT PERIOD`.
  final String? label;

  /// Inter heading.
  final String? title;

  /// Widget pinned to the right of the header row.
  final Widget? trailing;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? background;

  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final CrossAxisAlignment crossAxisAlignment;

  bool get _hasHeader =>
      label != null || title != null || trailing != null;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lgAll;

    Widget content = Padding(
      padding: padding ?? AppSpacing.cardInsets,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasHeader)
            _Header(label: label, title: title, trailing: trailing),
          if (_hasHeader && child != null) AppSpacing.gapMd,
          if (child != null) child!,
        ],
      ),
    );


    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.label, this.title, this.trailing});

  final String? label;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final texts = <Widget>[
      if (label != null) AppSectionLabel(label!),
      if (label != null && title != null) AppSpacing.gapXs,
      if (title != null) Text(title!, style: AppTypography.h2),
    ];

    if (trailing == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: texts,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: texts,
          ),
        ),
        AppSpacing.hGapSm,
        trailing!,
      ],
    );
  }
}
