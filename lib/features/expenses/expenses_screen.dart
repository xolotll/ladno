import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense.dart';
import 'expense_form_screen.dart';
import 'widgets/expense_tile.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen(
      {super.key, required this.repository, required this.month});

  final BudgetRepository repository;
  final DateTime month;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _search = TextEditingController();
  List<Expense> _expenses = [];
  List<BudgetCategory> _categories = [];
  String _currency = '₽';
  int? _filter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExpensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await Future.wait([
      widget.repository.getExpenses(widget.month),
      widget.repository.getCategories(),
      widget.repository.getCurrency()
    ]);
    if (!mounted) return;
    setState(() {
      _expenses = data[0] as List<Expense>;
      _categories = data[1] as List<BudgetCategory>;
      _currency = data[2] as String;
      _loading = false;
    });
  }

  Future<void> _openForm([Expense? expense]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ExpenseFormScreen(
                repository: widget.repository, expense: expense)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final filtered = _expenses.where((e) {
      final cat = _categories.where((c) => c.id == e.categoryId);
      final name = cat.isEmpty ? '' : cat.first.name;
      return (_filter == null || e.categoryId == _filter) &&
          ('$name ${e.note}'.toLowerCase().contains(q));
    }).toList();
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Поиск по расходам')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                        value: _filter,
                        decoration:
                            const InputDecoration(labelText: 'Категория'),
                        items: [
                          const DropdownMenuItem<int?>(
                              value: null, child: Text('Все категории')),
                          ..._categories.map((c) => DropdownMenuItem<int?>(
                              value: c.id, child: Text('${c.icon} ${c.name}')))
                        ],
                        onChanged: (v) => setState(() => _filter = v))
                  ]))),
          Padding(
              padding: const EdgeInsets.fromLTRB(3, 18, 3, 9),
              child: Row(children: [
                Text('Операции · ${filtered.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                const Spacer(),
                TextButton(onPressed: _openForm, child: const Text('Добавить'))
              ])),
          if (filtered.isEmpty)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Center(
                        child: Text(
                            _expenses.isEmpty
                                ? 'В этом месяце пока нет расходов'
                                : 'Ничего не найдено',
                            style: const TextStyle(color: AppColors.muted)))))
          else
            Card(
                child: Column(
                    children: filtered
                        .map((e) => ExpenseTile(
                            expense: e,
                            categories: _categories,
                            currency: _currency,
                            onTap: () => _openForm(e)))
                        .toList())),
        ]);
  }
}
