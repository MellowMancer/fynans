import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/add_transaction/add_transaction_cubit.dart';
import 'package:fynans/adapters/blocs/add_transaction/add_transaction_state.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/utils/tag_helper.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/use_cases/amount_parser.dart';

/// How far back a transaction may be dated.
const int _kBackdateYears = 1;

/// Provides the [AddTransactionCubit] (built from the repository in context)
/// and renders the transaction entry form.
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AddTransactionCubit(context.read<TransactionRepository>())
            ..loadSuggestions(),
      child: const _AddTransactionForm(),
    );
  }
}

class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm();

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _tagFormFieldKey = GlobalKey<FormFieldState<List<String>>>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _groupController = TextEditingController();
  final _partyController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedTags = [];
  late final List<String> _allTags = TagHelper.getAllTags();
  bool _creditFlag = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _groupController.dispose();
    _partyController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - _kBackdateYears, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddTransactionCubit>().save(
          amount: _amountController.text,
          party: _partyController.text,
          group: _groupController.text,
          tags: List.of(_selectedTags),
          isCredit: _creditFlag,
          note: _noteController.text,
          date: _selectedDate,
        );
  }

  void _onStatusChanged(AddTransactionState state) {
    switch (state.status) {
      case SaveStatus.success:
        _handleSaveSuccess();
      case SaveStatus.invalid:
      case SaveStatus.failure:
        _showMessage(state.message ?? 'Could not save transaction');
      case SaveStatus.idle:
      case SaveStatus.inProgress:
        break;
    }
  }

  void _handleSaveSuccess() {
    _showMessage('Transaction saved');
    _formKey.currentState!.reset();
    setState(() {
      _selectedTags.clear();
      _selectedDate = DateTime.now();
      _creditFlag = false;
      _partyController.text = '';
      _tagFormFieldKey.currentState?.didChange(<String>[]);
    });
    FocusScope.of(context).unfocus();
    context.read<AddTransactionCubit>().loadSuggestions();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTags() async {
    final results = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TagPickerSheet(
        items: _allTags,
        initialSelection: _selectedTags,
      ),
    );
    if (results == null) return;

    _tagFormFieldKey.currentState?.didChange(results);
    setState(() {
      _selectedTags
        ..clear()
        ..addAll(results);
    });
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
            AppSectionLabel('New entry', color: context.colors.accent),
            AppSpacing.gapXxs,
            Text('Add transaction', style: context.type.h1),
          ],
        ),
      ),
      body: BlocConsumer<AddTransactionCubit, AddTransactionState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) => _onStatusChanged(state),
        buildWhen: (p, c) => p.groups != c.groups || p.parties != c.parties,
        builder: (context, state) => Form(
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
                label: 'Amount',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      style: context.type.amount,
                      decoration: InputDecoration(
                        // `prefixText` is only painted while the field is
                        // focused or non-empty, so the symbol vanished at rest.
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            left: AppSpacing.md,
                            right: AppSpacing.sm,
                          ),
                          child: Text(
                            Fmt.currencySymbol,
                            style: context.type.amount,
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 0),
                        hintText: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) => parseAmount(value).error,
                    ),
                    AppSpacing.gapMd,
                    Row(
                      children: [
                        AppPill(
                          'Outflow',
                          icon: Icons.north_east_rounded,
                          tone: _creditFlag
                              ? AppPillTone.outline
                              : AppPillTone.danger,
                          onTap: () => _setCredit(false),
                        ),
                        AppSpacing.hGapSm,
                        AppPill(
                          'Inflow',
                          icon: Icons.south_west_rounded,
                          tone: _creditFlag
                              ? AppPillTone.success
                              : AppPillTone.outline,
                          onTap: () => _setCredit(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Section(
                label: 'Date',
                child: AppCard(
                  onTap: _presentDatePicker,
                  borderRadius: AppRadius.mdAll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: context.colors.inkMuted,
                      ),
                      AppSpacing.hGapMd,
                      Expanded(child: MonoText(Fmt.fullDate(_selectedDate))),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: context.colors.inkFaint,
                      ),
                    ],
                  ),
                ),
              ),
              _Section(
                label: 'Tags',
                child: FormField<List<String>>(
                  key: _tagFormFieldKey,
                  initialValue: _selectedTags,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Pick at least one tag'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _pickTags,
                        borderRadius: AppRadius.mdAll,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: field.hasError
                                  ? context.colors.danger
                                  : context.colors.border,
                            ),
                            borderRadius: AppRadius.mdAll,
                            color: context.colors.surface,
                          ),
                          child: _selectedTags.isEmpty
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: context.colors.inkMuted,
                                    ),
                                    AppSpacing.hGapSm,
                                    Text(
                                      'Choose one or more tags',
                                      style: context.type.body.copyWith(
                                        color: context.colors.inkFaint,
                                      ),
                                    ),
                                  ],
                                )
                              : Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (final tag in _selectedTags)
                                      AppPill(
                                        Fmt.capitalize(tag),
                                        icon: TagHelper.getIconForTag(tag),
                                        color: context.tagColor(tag),
                                        dense: true,
                                        onRemove: () {
                                          setState(
                                            () => _selectedTags.remove(tag),
                                          );
                                          field.didChange(_selectedTags);
                                        },
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      if (field.hasError) ...[
                        AppSpacing.gapXs,
                        Text(
                          field.errorText!,
                          style: context.type.small.copyWith(
                            color: context.colors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _Section(
                // "Sender" for inflows, "Recipient" for outflows.
                label: Fmt.partyLabel(isCredit: _creditFlag),
                child: _SuggestingField(
                  controller: _partyController,
                  suggestions: state.parties,
                  hintText: _creditFlag ? 'Who paid you?' : 'Who did you pay?',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a ${Fmt.partyLabel(isCredit: _creditFlag).toLowerCase()}'
                      : null,
                ),
              ),
              _Section(
                label: 'Group (optional)',
                child: _SuggestingField(
                  controller: _groupController,
                  suggestions: state.groups,
                  hintText: 'e.g. Trip to Goa',
                ),
              ),
              _Section(
                label: 'Note (optional)',
                child: TextFormField(
                  controller: _noteController,
                  style: context.type.body,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Anything worth remembering',
                  ),
                ),
              ),
              AppSpacing.gapSm,
              AppButton(
                label: 'Save transaction',
                icon: Icons.check_rounded,
                variant: AppButtonVariant.dark,
                expand: true,
                loading: state.status == SaveStatus.inProgress,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Switching direction only relabels the counterparty field (Sender vs
  /// Recipient) — it deliberately does not prefill or clear what was typed.
  void _setCredit(bool isCredit) => setState(() => _creditFlag = isCredit);
}

/// A labelled block in the form — keeps every field's spacing identical.
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

/// Text field backed by autocomplete suggestions.
class _SuggestingField extends StatelessWidget {
  const _SuggestingField({
    required this.controller,
    required this.suggestions,
    this.hintText,
    this.validator,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String? hintText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) => value.text.isEmpty
          ? const Iterable<String>.empty()
          : suggestions.where(
              (o) => o.toLowerCase().contains(value.text.toLowerCase()),
            ),
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (context, _, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: context.type.body.copyWith(color: context.colors.ink),
          decoration: InputDecoration(hintText: hintText),
          validator: validator,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 0,
          borderRadius: AppRadius.mdAll,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: context.colors.border),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    dense: true,
                    title: Text(option, style: context.type.body),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing tags — pills instead of a checkbox list, so the
/// picker matches how tags render everywhere else.
class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({required this.items, required this.initialSelection});

  final List<String> items;
  final List<String> initialSelection;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late final List<String> _selected = List.of(widget.initialSelection);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select tags', style: context.type.h2),
            AppSpacing.gapXs,
            Text(
              'Tap to toggle. Tags drive your analytics breakdown.',
              style: context.type.small,
            ),
            AppSpacing.gapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in widget.items)
                  AppPill(
                    Fmt.capitalize(tag),
                    icon: TagHelper.getIconForTag(tag),
                    color: _selected.contains(tag)
                        ? context.tagColor(tag)
                        : null,
                    tone: AppPillTone.outline,
                    onTap: () => setState(
                      () => _selected.contains(tag)
                          ? _selected.remove(tag)
                          : _selected.add(tag),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapXl,
            AppButton(
              label: 'Done',
              variant: AppButtonVariant.dark,
              expand: true,
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ],
        ),
      ),
    );
  }
}
