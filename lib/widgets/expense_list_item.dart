import 'package:flutter/material.dart';
import 'package:fynans/models/expense.dart';
import 'package:fynans/widgets/tag_icon_widget.dart';
import 'package:intl/intl.dart';

class ExpenseListItem extends StatefulWidget {
  const ExpenseListItem({super.key, required this.expense});

  final Expense expense;

  @override
  State<ExpenseListItem> createState() => _ExpenseListItemState();
}

class _ExpenseListItemState extends State<ExpenseListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  TagIconWidget(tags: widget.expense.tags),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.expense.tags.map((e) => e[0].toUpperCase() + e.substring(1)).join(', '),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${widget.expense.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(DateFormat.yMd().format(widget.expense.date)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: _isExpanded ? _buildExpandedDetails(context) : const SizedBox.shrink(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = widget.expense.note;
    final group = widget.expense.group;
    final recipient = widget.expense.recipient;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note != null && note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('Note: $note', style: textTheme.bodyMedium),
                      ),
                    if (group != null && group.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('Group: $group', style: textTheme.bodyMedium),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('Recipient: $recipient', style: textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}