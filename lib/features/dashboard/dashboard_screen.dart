import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense.dart';
import '../expenses/expense_form_screen.dart';
import '../expenses/widgets/expense_tile.dart';
import '../categories/category_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository, required this.month, required this.onMonthChanged});
  final BudgetRepository repository;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  List<BudgetCategory> _categories = [];
  List<Expense> _expenses = [];
  double _budget = 0;
  String _currency = '₽';
  bool _loading = true;
  double get _spent => _expenses.fold(0, (sum, item) => sum + item.amount);
  @override void initState() { super.initState(); _load(); }
  @override void didUpdateWidget(covariant DashboardScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.month != widget.month) _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      widget.repository.getCategories(), widget.repository.getExpenses(widget.month),
      widget.repository.getMonthlyBudget(), widget.repository.getCurrency(),
    ]);
    if (!mounted) return;
    setState(() { _categories = results[0] as List<BudgetCategory>; _expenses = results[1] as List<Expense>; _budget = results[2] as double; _currency = results[3] as String; _loading = false; });
  }
  double _categorySpent(int id) => _expenses.where((e) => e.categoryId == id).fold(0, (s, e) => s + e.amount);
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final remaining = _budget - _spent;
    final daysLeft = DateTime(widget.month.year, widget.month.month + 1, 0).day - DateTime.now().day + 1;
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      _budgetCard(remaining, daysLeft),
      const SizedBox(height: 18),
      _section('Мои категории', TextButton.icon(onPressed: _createCategory, icon: const Icon(Icons.add, size: 17), label: const Text('Добавить'))),
      if (_categories.isEmpty) _empty('Категорий пока нет', 'Добавьте категорию для учёта расходов.')
      else ..._categories.map(_categoryCard),
      const SizedBox(height: 10),
      Padding(padding: const EdgeInsets.fromLTRB(3, 7, 2, 9), child: Text('Последние расходы', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
      if (_expenses.isEmpty) _empty('Пока нет расходов', 'Нажмите +, чтобы добавить первую операцию.')
      else Card(child: Column(children: _expenses.take(5).map((e) => ExpenseTile(expense: e, categories: _categories, currency: _currency, onTap: () => _editExpense(e))).toList())),
    ]));
  }
  Widget _budgetCard(double remaining, int daysLeft) => Card(child: Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFFF0EAFB), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(formatMonth(widget.month), style: const TextStyle(color: AppColors.muted)), Text('${daysLeft.clamp(0, 31)} дн. осталось', style: const TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700, fontSize: 12))]),
      const SizedBox(height: 18), const Text('Остаток бюджета', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 4), Text(formatMoney(remaining, _currency), style: TextStyle(fontSize: 36, letterSpacing: -1, fontWeight: FontWeight.w800, color: remaining < 0 ? AppColors.danger : AppColors.ink)),
      Text(remaining < 0 ? 'Бюджет превышен' : 'Доступно в этом месяце', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 20), Row(children: [Expanded(child: _metric('Бюджет', formatMoney(_budget, _currency))), Expanded(child: _metric('Потрачено', formatMoney(_spent, _currency)))]),
      const SizedBox(height: 15), ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: _budget <= 0 ? 0 : (_spent / _budget).clamp(0, 1), minHeight: 8, color: AppColors.lavender, backgroundColor: AppColors.lavenderLight)),
      const SizedBox(height: 7), Align(alignment: Alignment.centerRight, child: Text(_budget <= 0 ? 'Бюджет не задан' : '${(_spent / _budget * 100).round()}% бюджета', style: const TextStyle(color: AppColors.muted, fontSize: 11))),
    ]),
  ));
  Widget _metric(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 11)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))]);
  Widget _section(String title, Widget action) => Padding(padding: const EdgeInsets.fromLTRB(3, 7, 2, 9), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), action]));
  Widget _categoryCard(BudgetCategory category) {
    final spent = _categorySpent(category.id); final limit = category.monthlyLimit;
    return Card(child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => _editCategory(category), child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
      Row(children: [Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.lavenderLight, borderRadius: BorderRadius.circular(13)), child: Text(category.icon, style: const TextStyle(fontSize: 19))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)), Text('Лимит ${formatMoney(limit, _currency)}', style: const TextStyle(color: AppColors.muted, fontSize: 11))])), Text(limit <= 0 ? '—' : '${(spent / limit * 100).round()}%', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: limit <= 0 ? 0 : (spent / limit).clamp(0, 1), minHeight: 6, color: AppColors.lavender, backgroundColor: AppColors.lavenderLight)),
      const SizedBox(height: 9), Row(children: [Expanded(child: _metric('Потрачено', formatMoney(spent, _currency))), Expanded(child: _metric('Осталось', formatMoney(limit - spent, _currency)))]),
    ]))));
  }
  Widget _empty(String title, String subtitle) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.savings_outlined, color: AppColors.lavender, size: 32), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12))])));
  Future<void> _createCategory() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryFormScreen(repository: widget.repository))); await _load(); }
  Future<void> _editCategory(BudgetCategory category) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryFormScreen(repository: widget.repository, category: category))); await _load(); }
  Future<void> _editExpense(Expense expense) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseFormScreen(repository: widget.repository, expense: expense))); await _load(); }
}
