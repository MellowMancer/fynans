import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/widgets/app_drawer.dart';
import 'package:fynans/screens/analytics_screen.dart';
import 'package:fynans/screens/test_sms_screen.dart';
import 'package:fynans/screens/transactions_list_screen.dart';
import 'package:fynans/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:fynans/scam/protection_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // final _readSmsService = ReadSmsService();
  // final _smsParserService = SmsParserService();

  static const List<String> _widgetTitles = <String>[
    'Overview',
    'Analytics',
    'Test SMS',
    'Protection',
  ];

  static final List<Widget> _widgetOptions = <Widget>[
    MultiBlocProvider(
      providers: [
        BlocProvider<TransactionCubit>(
          create: (context) => TransactionCubit(HiveService()),
        ),
        BlocProvider<AdvancedViewBloc>(
          create: (context) => AdvancedViewBloc()
            ..add(AdvancedViewDataFetched()),
        ),
      ],
      child: const TransactionsListScreen(),
    ),
    const AnalyticsScreen(),
    const TestSmsScreen(),
    const ProtectionScreen(),
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
  //       // TODO: Parse amount, party, etc., and save to Isar.
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
      appBar: AppBar(
        title: Text(_widgetTitles.elementAt(_selectedIndex)),
      ),
      endDrawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Improves UI for 4+ items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'TestSMS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: 'Protection',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}