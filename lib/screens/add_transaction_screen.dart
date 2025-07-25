import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:intl/intl.dart';
import 'package:fynans/utils/tag_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _hiveService = HiveService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _groupController = TextEditingController();
  final _partyController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedTags = [];
  List<String> _allTags = [];
  List<String> _existingGroups = [];
  List<String> _existingParties = [];
  bool _creditFlag = false;
  String party = '';


  @override
  void initState() {
    super.initState();
    _allTags = TagHelper.getAllTags();
    _loadSuggestions();
  }

  void _loadSuggestions() async {
    final groups = await _hiveService.getAllGroups();
    final parties = await _hiveService.getAllParties();
    if (mounted) {
      setState(() {
        _existingGroups = groups;
        _existingParties = parties;
      });
    }
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
  
  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final groupInputString = _groupController.text;
      final List<String> groups = groupInputString
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList();

      final newTransaction = Transaction()
        ..amount = double.parse(_amountController.text)
        ..date = _selectedDate
        ..tags = _selectedTags
        ..note = _noteController.text.isNotEmpty ? _noteController.text : null
        ..group = groups
        ..party = _partyController.text.trim()
        ..isCredit = _creditFlag;

      await _hiveService.saveTransaction(newTransaction);


      // Check if the widget is still in the tree before using its context.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction Saved!'),
          backgroundColor: Colors.green,
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
      _loadSuggestions();
    }
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
      body: SingleChildScrollView(
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
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter an amount'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text('Credit', textScaler: TextScaler.linear(0.9)),
                      const SizedBox(height: 1),
                      Switch(
                        value: _creditFlag,
                        onChanged: (value) => setState(() {
                          _creditFlag = value;
                          _partyController.text = value ? 'Me' : '';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat.yMd().format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _presentDatePicker,
                    icon: const Icon(Icons.calendar_month),
                  ),
                ],
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
                  return _existingGroups.where((String option) {
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
                      // _partyController.value = textEditingController.value;
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
                  return _existingParties.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _partyController.text = selection;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.save),
                label: const Text('Save Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _tagFormFieldKey = GlobalKey<FormFieldState>();

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
    );
  }
}
