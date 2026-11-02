import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/budget_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../expenses/expenses_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../expenses/expense_form_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repository});
  final BudgetRepository repository;
  @override State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _refreshKey = 0;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  void _setMonth(DateTime value) => setState(() => _month = DateTime(value.year, value.month));

  @override Widget build(BuildContext context) {
    final titles = ['Главная', 'Операции', 'Статистика', 'Настройки'];
    final pages = [
      DashboardScreen(key: ValueKey('dashboard-$_refreshKey'), repository: widget.repository, month: _month, onMonthChanged: _setMonth),
      ExpensesScreen(key: ValueKey('expenses-$_refreshKey'), repository: widget.repository, month: _month),
      StatisticsScreen(key: ValueKey('statistics-$_refreshKey'), repository: widget.repository, month: _month),
      SettingsScreen(key: ValueKey('settings-$_refreshKey'), repository: widget.repository),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ЛИЧНЫЕ ФИНАНСЫ', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
          Text(titles[_index], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        ]),
        actions: [if (_index != 3) IconButton(tooltip: 'Выбрать месяц', onPressed: _pickMonth, icon: const Icon(Icons.calendar_month_outlined, color: AppColors.lavender))],
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 3 ? null : FloatingActionButton(
        onPressed: () => _openAddExpense(context),
        backgroundColor: AppColors.lavender,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 29),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() { _index = value; _refreshKey++; }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Операции'),
          NavigationDestination(icon: Icon(Icons.donut_small_outlined), label: 'Статистика'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(context: context, initialDate: _month, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDatePickerMode: DatePickerMode.year);
    if (selected != null) _setMonth(selected);
  }
  Future<void> _openAddExpense(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseFormScreen(repository: widget.repository)));
    if (mounted) setState(() => _refreshKey++);
  }
}
