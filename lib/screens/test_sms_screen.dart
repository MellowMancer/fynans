import 'package:flutter/material.dart';
import 'package:fynans/services/parsed_transaction.dart'; // <-- Use the new, correct file name
import 'package:fynans/services/read_sms_service.dart';
import 'package:fynans/services/sms_parser_service.dart';

class TestSmsScreen extends StatefulWidget {
  const TestSmsScreen({super.key});

  @override
  State<TestSmsScreen> createState() => _TestSmsScreenState();
}

class _TestSmsScreenState extends State<TestSmsScreen> {
  final _readSmsService = ReadSmsService();
  final _smsParserService = SmsParserService();

  bool _isLoading = true;
  // This state variable now holds the final, parsed transaction details.
  List<ParsedTransactionDetails> _parsedTransactions = [];

  @override
  void initState() {
    super.initState();
    _readAndParseSms();
  }

  Future<void> _readAndParseSms() async {
    if (mounted) setState(() => _isLoading = true);

    // 1. Get all SMS messages
    final allMessages = await _readSmsService.getNewSms();

    // 2. Filter and Parse in one step
    final successfulParses = allMessages.map((msg) {
        // First, check if it's a transaction SMS at all
        if (msg.body != null && msg.sender != null && _smsParserService.isTransactionSms(msg.sender!, msg.body!)) {
            // If it is, try to parse it. This will return a details object or null.
            return _smsParserService.parseTransactionDetails(msg);
        }
        return null;
    }).whereType<ParsedTransactionDetails>().toList(); // .whereType conveniently filters out all the nulls.

    if (mounted) {
      setState(() {
        _parsedTransactions = successfulParses;
        _isLoading = false;
      });
      debugPrint('Found and parsed ${_parsedTransactions.length} new transaction messages.');
    }
  }

  Widget _buildSmsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_parsedTransactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _readAndParseSms,
        child: const Center(child: Text('No new parsable transaction messages found.')),
      );
    }

    return RefreshIndicator(
      onRefresh: _readAndParseSms,
      child: ListView.builder(
        itemCount: _parsedTransactions.length,
        itemBuilder: (context, index) {
          final details = _parsedTransactions[index];
          final isDebit = details.type == TransactionType.debit;
          final icon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;
          final color = isDebit ? Colors.red.shade400 : Colors.green.shade400;
          final amountText = '₹${details.amount.toStringAsFixed(2)}';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Icon(icon, color: color),
              title: Text(
                details.recipientOrSender ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'A/c: ${details.accountNumber ?? 'N/A'}\n${details.date.toLocal()}',
              ),
              trailing: Text(
                amountText,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parsed SMS Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _readAndParseSms,
            tooltip: 'Refresh SMS',
          ),
        ],
      ),
      body: _buildSmsList(),
    );
  }
}