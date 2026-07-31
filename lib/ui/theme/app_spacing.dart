import 'package:flutter/widgets.dart';

/// Spacing scale (4pt base). Use these instead of ad-hoc numbers so rhythm
/// stays consistent across screens.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard page gutter.
  static const double gutter = 16;

  static const EdgeInsets cardInsets = EdgeInsets.all(lg);

  /// Every page's main scroll view uses the same vertical rhythm — symmetric,
  /// so the list is inset equally at both ends.
  static const double _scrollTop = sm;
  static const double _scrollBottom = _scrollTop;

  /// The one padding every page's scroll view uses. Cards sit flush inside it
  /// and never carry their own horizontal margin, so the gutter is defined in
  /// exactly one place.
  static const EdgeInsets pageInsets =
      EdgeInsets.fromLTRB(gutter, _scrollTop, gutter, _scrollBottom);

  /// Vertical space between stacked cards.
  static const double cardGap = md;

  /// Applied as a card's bottom margin inside a list.
  static const EdgeInsets cardGapInsets = EdgeInsets.only(bottom: cardGap);

  /// Space between a page's header card and the content below it — wider than
  /// [cardGap] so the header reads as its own block.
  static const EdgeInsets headerGapInsets = EdgeInsets.only(bottom: xl);

  /// Dense list rows (transaction items) sit tighter than standalone cards.
  static const double rowGap = sm;
  static const EdgeInsets rowGapInsets = EdgeInsets.only(bottom: rowGap);

  /// Widget form, for cards laid out in a Column/ListView children list.
  static const Widget gapCard = SizedBox(height: cardGap);

  /// Vertical gaps, as widgets, to avoid `SizedBox(height: …)` noise.
  static const Widget gapXxs = SizedBox(height: xxs);
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);

  /// Horizontal gaps.
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Animation durations.
abstract final class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
}
