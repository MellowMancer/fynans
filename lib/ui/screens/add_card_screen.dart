import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/add_card/add_card_cubit.dart';
import 'package:fynans/adapters/blocs/add_card/add_card_state.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// Provides the [AddCardCubit] and renders the add-card form: issuer, last
/// 2-4 digits, required credit limit, optional nickname. No full card
/// numbers, ever.
///
/// [fromDetection], when set, pre-fills issuer + last4 from a "is this your
/// card?" prompt (`DetectedCardsBanner`) — the credit limit still has to be
/// typed in, since a spend SMS only ever reports what's currently
/// *available*, never the card's total limit.
class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key, this.fromDetection});

  final DetectedCard? fromDetection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddCardCubit(
        context.read<CardRepository>(),
        context.read<TransactionRepository>(),
        context.read<DetectedCardRepository>(),
        context.read<CardStatementRepository>(),
      ),
      child: _AddCardForm(fromDetection: fromDetection),
    );
  }
}

class _AddCardForm extends StatefulWidget {
  const _AddCardForm({this.fromDetection});

  final DetectedCard? fromDetection;

  @override
  State<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<_AddCardForm> {
  final _formKey = GlobalKey<FormState>();
  late final _issuerController =
      TextEditingController(text: widget.fromDetection?.issuerGuess);
  late final _last4Controller =
      TextEditingController(text: widget.fromDetection?.last4);
  final _limitController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _issuerController.dispose();
    _last4Controller.dispose();
    _limitController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddCardCubit>().save(
          issuer: _issuerController.text,
          last4: _last4Controller.text,
          creditLimit: _limitController.text,
          nickname: _nicknameController.text,
          fromDetection: widget.fromDetection,
        );
  }

  void _onStatusChanged(AddCardState state) {
    switch (state.status) {
      case AddCardStatus.success:
        final count = state.importedCount ?? 0;
        _showMessage(count > 0
            ? 'Card added — $count transaction${count == 1 ? '' : 's'} found'
            : 'Card added');
        Navigator.pop(context);
      case AddCardStatus.invalid:
      case AddCardStatus.failure:
        _showMessage(state.message ?? 'Could not save card');
      case AddCardStatus.idle:
      case AddCardStatus.inProgress:
      case AddCardStatus.sweepingSms:
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSectionLabel('New card', color: context.colors.accent),
            AppSpacing.gapXxs,
            Text('Add card', style: context.type.h1),
          ],
        ),
      ),
      body: BlocConsumer<AddCardCubit, AddCardState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) => _onStatusChanged(state),
        builder: (context, state) {
          // The card is already saved by this point — re-showing the form
          // would invite editing something that no longer makes sense to
          // edit here, so this replaces it rather than overlaying it.
          if (state.status == AddCardStatus.sweepingSms) {
            return _SweepingSmsView(
              scanned: state.scannedCount,
              total: state.totalCount,
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                AppSpacing.xxxl,
              ),
              children: [
                _Section(
                  label: 'Issuer',
                  child: TextFormField(
                    controller: _issuerController,
                    style: context.type.body,
                    decoration: const InputDecoration(
                        hintText: 'e.g. HDFC, SBI Card, Amex'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Enter an issuer'
                            : null,
                  ),
                ),
                _Section(
                  label: 'Last 2-4 digits',
                  child: TextFormField(
                    controller: _last4Controller,
                    style: context.type.amount,
                    decoration: const InputDecoration(hintText: '1234'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.length < 2 || trimmed.length > 4) {
                        return 'Enter 2 to 4 digits';
                      }
                      return null;
                    },
                  ),
                ),
                _Section(
                  label: 'Credit limit',
                  child: TextFormField(
                    controller: _limitController,
                    style: context.type.amount,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.sm,
                        ),
                        child: Text(Fmt.currencySymbol,
                            style: context.type.amount),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 0),
                      hintText: '0.00',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      final limit = double.tryParse((value ?? '').trim());
                      if (limit == null || limit <= 0) {
                        return 'Enter a credit limit greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                _Section(
                  label: 'Nickname (optional)',
                  child: TextFormField(
                    controller: _nicknameController,
                    style: context.type.body,
                    decoration:
                        const InputDecoration(hintText: 'e.g. Travel card'),
                  ),
                ),
                AppSpacing.gapSm,
                AppButton(
                  label: 'Save card',
                  icon: Icons.check_rounded,
                  variant: AppButtonVariant.dark,
                  expand: true,
                  loading: state.status == AddCardStatus.inProgress,
                  onPressed: _submitForm,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shown after the card is saved, while the SMS inbox is re-swept for its
/// history — see [AddCardCubit.save]. Real progress, not a bare spinner:
/// [scanned]/[total] come from `SmsIntakeService.catchUp`'s onProgress.
class _SweepingSmsView extends StatelessWidget {
  const _SweepingSmsView({this.scanned, this.total});

  final int? scanned;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Null until the first progress tick arrives (or total is genuinely 0,
    // e.g. an empty inbox) — either way, fall back to an indeterminate bar
    // rather than dividing by zero or showing a stale 0%.
    final hasProgress = total != null && total! > 0;
    final progress = hasProgress ? (scanned ?? 0) / total! : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sms_outlined, size: 22, color: colors.accent),
            ),
            AppSpacing.gapLg,
            Text(
              'Parsing SMS, please wait…',
              style: context.type.h3,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXs,
            Text(
              'Checking your inbox for this card\'s past transactions.',
              style: context.type.small,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: AppRadius.pillAll,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colors.surfaceMuted,
                  color: colors.accent,
                ),
              ),
            ),
            AppSpacing.gapSm,
            MonoText.small(
              hasProgress ? 'Scanned $scanned of $total messages' : 'Starting…',
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled block in the form — keeps every field's spacing identical.
/// Same shape as `add_transaction_screen.dart`'s private `_Section`.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionLabel(label),
          AppSpacing.gapSm,
          child,
        ],
      ),
    );
  }
}
