import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ui/screens/add_card_screen.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// "Is this your card?" prompts for cards seen in SMS but not registered.
/// Renders nothing when there's nothing pending — sits above the card list
/// on [CardsScreen] regardless of whether any cards are registered yet.
class DetectedCardsBanner extends StatelessWidget {
  const DetectedCardsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DetectedCard>>(
      stream: context.read<DetectedCardRepository>().watchPending(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? const <DetectedCard>[];
        // A zero-size child, not a padded-but-empty box — this sits above a
        // BlocBuilder that has its own empty/loading states to render.
        if (cards.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final card in cards)
                Padding(
                  padding: AppSpacing.cardGapInsets,
                  child: _DetectedCardCard(card: card),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetectedCardCard extends StatelessWidget {
  const _DetectedCardCard({required this.card});

  final DetectedCard card;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      background: context.colors.accentSoft,
      label: 'Detected card',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Is this your ${card.issuerGuess} card ending ${card.last4}?',
            style: context.type.body,
          ),
          AppSpacing.gapXs,
          MonoText.small(
            card.sightingCount > 1
                ? 'Seen ${card.sightingCount} times, most recently '
                    '${Fmt.dayMonth(card.lastSeen)}'
                : 'Seen ${Fmt.dayMonth(card.lastSeen)}',
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Not mine',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: () =>
                      context.read<DetectedCardRepository>().dismiss(card),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: AppButton(
                  label: 'Add card',
                  variant: AppButtonVariant.dark,
                  size: AppButtonSize.sm,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCardScreen(fromDetection: card),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
