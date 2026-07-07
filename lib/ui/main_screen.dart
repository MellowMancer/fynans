import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/ui/widgets/app_drawer.dart';
import 'package:fynans/ui/screens/analytics_screen.dart';
import 'package:fynans/ui/screens/test_sms_screen.dart';
import 'package:fynans/ui/screens/transactions_list_screen.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/ports/transaction_repository.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<String> _widgetTitles = <String>[
    'Overview',
    'Analytics',
    'Test SMS',
  ];

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>(
            create: (context) =>
                TransactionCubit(context.read<TransactionRepository>()),
          ),
          BlocProvider<AdvancedViewBloc>(
            create: (context) =>
                AdvancedViewBloc(context.read<TransactionRepository>())
                  ..add(AdvancedViewDataFetched()),
          ),
        ],
        child: const TransactionsListScreen(),
      ),
      const AnalyticsScreen(),
      const TestSmsScreen(),
    ];
  }

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
        type: BottomNavigationBarType.fixed,
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
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}