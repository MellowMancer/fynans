import 'package:flutter/material.dart';
import 'package:fynans/services/parsed_transaction.dart';
import 'package:fynans/services/read_sms_service.dart';
import 'package:fynans/services/sms_parser_service.dart';

class TransactionDisplayData {
  final ParsedTransactionDetails details;
  final String sender; // This will hold the bank name

  TransactionDisplayData({required this.details, required this.sender});
}

class TestSmsScreen extends StatefulWidget {
  const TestSmsScreen({super.key});

  @override
  State<TestSmsScreen> createState() => _TestSmsScreenState();
}

class _TestSmsScreenState extends State<TestSmsScreen> {
  final _readSmsService = ReadSmsService();
  final _smsParserService = SmsParserService();

  bool _isLoading = true;
  // --- MODIFIED: The state variable now holds our new data class ---
  List<TransactionDisplayData> _transactionsToDisplay = [];

  @override
  void initState() {
    super.initState();
    _readAndParseSms();
  }

  // --- MODIFIED: This method now stores the sender along with the parsed details ---
  Future<void> _readAndParseSms() async {
    if (mounted) setState(() => _isLoading = true);
    debugPrint("--- Starting SMS Read and Parse ---");

    // Non-consuming read: re-scan the whole inbox every time so this diagnostic
    // list always shows ALL parsable transactions, including on refresh.
    final allMessages = await _readSmsService.getAllSms();
    debugPrint("Step 1: Found ${allMessages.length} total messages in inbox.");

    // The logic now populates a list of our new TransactionDisplayData class
    final List<TransactionDisplayData> successfulParses = [];

    for (final msg in allMessages) {
      final details = _smsParserService.parseTransactionDetails(
        sender: msg.sender,
        body: msg.body,
        date: msg.date,
      );

      if (details != null) {
        // SUCCESS! Store both the details and the sender.
        successfulParses.add(
          TransactionDisplayData(details: details, sender: msg.sender),
        );
      }
    }
    
    debugPrint("Successfully parsed ${successfulParses.length} transactions.");
    debugPrint("--- Ending SMS Read and Parse ---");

    if (successfulParses.isNotEmpty) {
      final first = successfulParses.first;
      debugPrint("Amount: ${first.details.amount}");
      debugPrint("Type: ${first.details.type}");
      debugPrint("Date: ${first.details.date}");
      debugPrint("Balance: ${first.details.balance}");
      debugPrint("Account Number: ${first.details.accountNumber}");
      debugPrint("Merchant: ${first.details.merchant}");
    }
    


    if (mounted) {
      setState(() {
        // Update the state with the new list
        _transactionsToDisplay = successfulParses;
        _isLoading = false;
      });
    }
  }

  Widget _buildSmsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_transactionsToDisplay.isEmpty) {
      return RefreshIndicator(
        onRefresh: _readAndParseSms,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            const Center(child: Text('No new parsable transaction messages found.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _readAndParseSms,
      child: ListView.builder(
        // --- MODIFIED: Use the new list's length ---
        itemCount: _transactionsToDisplay.length,
        itemBuilder: (context, index) {
          // --- MODIFIED: Get the combined data object ---
          final transactionData = _transactionsToDisplay[index];
          final details = transactionData.details;
          final bankName = transactionData.sender;

          IconData icon;
          Color color;
          switch (details.type) {
            case TransactionType.debit:
              icon = Icons.arrow_upward;
              color = Theme.of(context).colorScheme.error;
              break;
            case TransactionType.credit:
              icon = Icons.arrow_downward;
              color = Theme.of(context).colorScheme.primary;
              break;
            case TransactionType.declined:
              icon = Icons.block;
              color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
              break;
            default:
              icon = Icons.help_outline;
              color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
          }

          final amountText = '₹${details.amount.toStringAsFixed(2)}';

          // --- MODIFIED: A much more informative subtitle ---
          // It dynamically builds a line of text with all available info.
          final List<String> firstLineParts = [];
          firstLineParts.add(bankName);
          if (details.accountNumber != null) {
            firstLineParts.add('A/c: ${details.accountNumber}');
          }
          if (details.balance != null) {
            firstLineParts.add('Bal: ₹${details.balance!.toStringAsFixed(2)}');
          }
          
          final String firstLine = firstLineParts.join('  •  ');
          final String subtitleText = '$firstLine\n${details.date.toLocal()}';
          // --- END OF SUBTITLE MODIFICATION ---

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(icon, color: color),
              title: Text(
                details.merchant ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              // Use the new, richer subtitle
              subtitle: Text(subtitleText), 
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