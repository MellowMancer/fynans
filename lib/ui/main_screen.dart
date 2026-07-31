import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/ui/widgets/app_drawer.dart';
import 'package:fynans/ui/screens/analytics_screen.dart';
import 'package:fynans/ui/screens/test_sms_screen.dart';
import 'package:fynans/ui/screens/transactions_list_screen.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// A destination in the bottom navigation bar.
class _Destination {
  const _Destination({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination(
      eyebrow: 'Your Money',
      title: 'Expenses',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'EXPENSES',
    ),
    _Destination(
      eyebrow: 'Oh, you prefer charts?',
      title: 'Analytics',
      icon: Icons.donut_small_outlined,
      activeIcon: Icons.donut_small,
      label: 'ANALYTICS',
    ),
    _Destination(
      eyebrow: 'DEV',
      title: 'Parsed SMS',
      icon: Icons.sms_outlined,
      activeIcon: Icons.sms,
      label: 'SMS (DEV)',
    ),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
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

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: AppSpacing.gutter,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSectionLabel(destination.eyebrow, color: context.colors.accent),
            AppSpacing.gapXxs,
            Text(destination.title, style: context.type.h1),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: context.colors.ink),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Menu',
            ),
          ),
          AppSpacing.hGapSm,
        ],
      ),
      endDrawer: const AppDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            for (final d in _destinations)
              BottomNavigationBarItem(
                icon: Icon(d.icon),
                activeIcon: Icon(d.activeIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
