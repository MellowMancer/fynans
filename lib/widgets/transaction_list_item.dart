import 'package:flutter/material.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/widgets/tag_icon_widget.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatefulWidget {
  const TransactionListItem({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
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
                  TagIconWidget(tags: widget.transaction.tags),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.transaction.tags.map((e) => e[0].toUpperCase() + e.substring(1)).join(', '),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${widget.transaction.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(DateFormat.yMd().format(widget.transaction.date)),
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
    final note = widget.transaction.note;
    final group = widget.transaction.group;
    final party = widget.transaction.party;

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
                    if (group.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('Group: $group', style: textTheme.bodyMedium),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('Recipient: $party', style: textTheme.bodyMedium),
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