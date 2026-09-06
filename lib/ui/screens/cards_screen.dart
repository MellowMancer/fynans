import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/cards/cards_cubit.dart';
import 'package:fynans/adapters/blocs/cards/cards_state.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_card_screen.dart';
import 'package:fynans/ui/screens/card_detail_screen.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/widgets/card_tile.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/detected_cards_banner.dart';

/// List of registered cards with their live spend summaries.
///
/// Builds its own [Scaffold] to host the add-card FAB — the same choice
/// `TransactionsListScreen` makes, as opposed to `AnalyticsScreen`/
/// `TestSmsScreen`, which inherit `MainScreen`'s single Scaffold.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CardsCubit(
        context.read<TransactionRepository>(),
        context.read<CardRepository>(),
        context.read<CardStatementRepository>(),
      )..loadCards(),
      child: const _CardsView(),
    );
  }
}

void _openAddCard(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCardScreen()),
    );

class _CardsView extends StatelessWidget {
  const _CardsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddCard(context),
        tooltip: 'Add card',
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Above the card list, and visible even with zero registered
          // cards — a fresh install with no cards yet is exactly when a
          // detected sighting is most useful to surface.
          const DetectedCardsBanner(),
          Expanded(
            child: BlocBuilder<CardsCubit, CardsState>(
              builder: (context, state) {
                if (state is CardsLoadFailure) {
                  return AppErrorView(
                    title: 'Could not load cards',
                    message: state.error,
                    onRetry: () => context.read<CardsCubit>().loadCards(),
                  );
                }
                if (state is! CardsLoadSuccess) {
                  return const AppLoading();
                }
                if (state.cards.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.credit_card_outlined,
                    title: 'No cards yet',
                    message: 'Add a card to track its spends separately '
                        'from your bank transactions.',
                    action: AppButton(
                      label: 'Add a card',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.dark,
                      onPressed: () => _openAddCard(context),
                    ),
                  );
                }
                return ListView(
                  padding: AppSpacing.pageInsets,
                  children: [
                    for (final c in state.cards)
                      Padding(
                        padding: AppSpacing.cardGapInsets,
                        child: CardTile(
                          summary: c.summary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<CardsCubit>(),
                                child: CardDetailScreen(
                                    cardId: c.summary.card.id!),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
