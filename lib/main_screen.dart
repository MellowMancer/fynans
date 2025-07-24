import 'package:flutter/material.dart';
import 'package:fynans/screens/expenses_list_screen.dart';
import 'package:fynans/screens/analytics_screen.dart';
import 'package:fynans/screens/advanced_view.dart';
import 'package:fynans/services/read_sms_service.dart';
import 'package:fynans/services/sms_parser_service.dart';
import 'package:fynans/screens/test_sms_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _readSmsService = ReadSmsService();
  final _smsParserService = SmsParserService();

  static const List<Widget> _widgetOptions = <Widget>[
    ExpensesListScreen(),
    AdvancedViewScreen(),
    AnalyticsScreen(),
    TestSmsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // _readAndFilterSms();
  }

  // void _readAndFilterSms() async {
  //   final newMessages = await _readSmsService.getNewSms();

  //   // 2. Filter for transaction messages using our parser service.
  //   final transactionMessages = newMessages.where((msg) {
  //     if (msg.body == null) return false;
  //     return _smsParserService.isTransactionSms(msg.body!);
  //   }).toList();

  //   if (mounted) {
  //     debugPrint('Found ${transactionMessages.length} new transaction messages.');

  //     for (var message in transactionMessages) {
  //       debugPrint('--- Transaction SMS ---');
  //       debugPrint('From: ${message.sender}, Body: ${message.body}');
  //       // TODO: Parse amount, recipient, etc., and save to Isar.
  //     }
  //   }
  // }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined), 
            label: 'Views'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'TestSMS',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
