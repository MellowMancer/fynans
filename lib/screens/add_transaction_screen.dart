import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/blocs/add_transaction/add_transaction_cubit.dart';
import 'package:fynans/blocs/add_transaction/add_transaction_state.dart';
import 'package:fynans/repositories/transaction_repository.dart';
import 'package:intl/intl.dart';
import 'package:fynans/utils/amount_parser.dart';
import 'package:fynans/utils/tag_helper.dart';

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
  List<String> _allTags = [];
  bool _creditFlag = false;

  @override
  void initState() {
    super.initState();
    _allTags = TagHelper.getAllTags();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _groupController.dispose();
    _partyController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      _selectedDate = pickedDate ?? _selectedDate;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction Saved!'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showMultiSelectTagsDialog() async {
    final List<String>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          items: _allTags,
          initialSelectedItems: _selectedTags,
        );
      },
    );

    if (results != null) {
      // Using FormField's didChange to trigger validation
      _tagFormFieldKey.currentState?.didChange(results);
      setState(() {
        _selectedTags.clear();
        _selectedTags.addAll(results);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: BlocConsumer<AddTransactionCubit, AddTransactionState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) => _onStatusChanged(state),
        buildWhen: (previous, current) =>
            previous.groups != current.groups ||
            previous.parties != current.parties,
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.currency_rupee),
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
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        'Credit',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Switch(
                        value: _creditFlag,
                        onChanged: (value) => setState(() {
                          _creditFlag = value;
                          _partyController.text = value ? 'Me' : '';
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _presentDatePicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMMd().format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FormField<List<String>>(
                key: _tagFormFieldKey,
                initialValue: _selectedTags,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select at least one tag.';
                  }
                  return null;
                },
                builder: (formFieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _showMultiSelectTagsDialog,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tags',
                            prefixIcon: const Icon(Icons.label),
                            errorText: formFieldState.errorText,
                          ),
                          child: _selectedTags.isEmpty
                              ? const Text('Select one or more tags')
                              : Wrap(
                                  spacing: 6.0,
                                  runSpacing: 0.0,
                                  children: _selectedTags.map((tag) {
                                    return Chip(
                                      label: Text(
                                        tag[0].toUpperCase() + tag.substring(1),
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedTags.remove(tag);
                                          formFieldState.didChange(
                                            _selectedTags,
                                          );
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextFormField(
                        controller: _groupController,
                        focusNode: focusNode,
                        onFieldSubmitted: (String value) {
                          onFieldSubmitted();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Group (Optional)',
                          prefixIcon: Icon(Icons.group_work),
                        ),
                      );
                    },
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return state.groups.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _groupController.text = selection;
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextFormField(
                        controller: _partyController,
                        readOnly: _creditFlag,
                        focusNode: focusNode,
                        onFieldSubmitted: (String value) {
                          onFieldSubmitted();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Party',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Please enter a party'
                            : null,
                      );
                    },
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return state.parties.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _partyController.text = selection;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Save Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;
  final List<String> initialSelectedItems;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.initialSelectedItems,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  final List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.initialSelectedItems);
  }

  void _onItemCheckedChange(String itemValue, bool checked) {
    setState(() {
      if (checked) {
        _selectedItems.add(itemValue);
      } else {
        _selectedItems.remove(itemValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Tags'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items.map((item) {
            return CheckboxListTile(
              value: _selectedItems.contains(item),
              title: Text(item[0].toUpperCase() + item.substring(1)),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => _onItemCheckedChange(item, checked!),
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          child: const Text('OK'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
