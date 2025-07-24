import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
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
  

  // State for holding messages and loading status
  bool _isLoading = true;
  List<SmsMessage> _transactionMessages = [];

  @override
  void initState() {
    super.initState();
    _readAndFilterSms();
  }

  Future<void> _readAndFilterSms() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final newMessages = await _readSmsService.getNewSms();

    final transactionMessages = newMessages.where((msg) {
      if (msg.body == null) return false;
      return _smsParserService.isTransactionSms(msg.sender!, msg.body!);
    }).toList();

    if (mounted) {
      setState(() {
        _transactionMessages = transactionMessages;
        _isLoading = false;
      });

      debugPrint('Found ${_transactionMessages.length} new transaction messages.');
    }
  }

  /// Builds the list view to display the SMS messages.
  Widget _buildSmsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactionMessages.isEmpty) {
      return const Center(
        child: Text('No new transaction messages found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _readAndFilterSms,
      child: ListView.builder(
        itemCount: _transactionMessages.length,
        itemBuilder: (context, index) {
          final message = _transactionMessages[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.message),
              title: Text(message.sender ?? 'Unknown Sender'),
              subtitle: Text(
                message.body ?? 'No content',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This screen has its own Scaffold, making it a self-contained page.
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _readAndFilterSms,
            tooltip: 'Refresh SMS',
          ),
        ],
      ),
      body: _buildSmsList(),
    );
  }
}

