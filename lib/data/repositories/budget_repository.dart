import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense.dart';

/// Local-first repository. On the web SharedPreferences uses browser storage;
/// on mobile it uses the platform preferences store.
class BudgetRepository {
  BudgetRepository();

  static const _categoriesKey = 'ladno.categories.v1';
  static const _expensesKey = 'ladno.expenses.v1';
  static const _budgetKey = 'ladno.monthly_budget.v1';
  static const _currencyKey = 'ladno.currency.v1';
  bool _loaded = false;
  List<BudgetCategory> _categories = [];
  List<Expense> _expenses = [];
  double _budget = 50000;
  String _currency = '₽';
  int _nextCategoryId = 1;
  int _nextExpenseId = 1;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawCategories = prefs.getString(_categoriesKey);
    final rawExpenses = prefs.getString(_expensesKey);
    if (rawCategories == null) {
      _categories = [
        const BudgetCategory(
            id: 1, name: 'Продукты', icon: '🛒', monthlyLimit: 15000),
        const BudgetCategory(
            id: 2, name: 'Транспорт', icon: '🚕', monthlyLimit: 5000),
        const BudgetCategory(
            id: 3, name: 'Дом', icon: '🏠', monthlyLimit: 12000),
        const BudgetCategory(
            id: 4, name: 'Кафе', icon: '☕', monthlyLimit: 5000),
        const BudgetCategory(
            id: 5, name: 'Покупки', icon: '🛍️', monthlyLimit: 8000),
      ];
    } else {
      _categories = (jsonDecode(rawCategories) as List)
          .map((e) =>
              BudgetCategory.fromMap(Map<String, Object?>.from(e as Map)))
          .toList();
    }
    if (rawExpenses != null) {
      _expenses = (jsonDecode(rawExpenses) as List)
          .map((e) => Expense.fromMap(Map<String, Object?>.from(e as Map)))
          .toList();
    }
    _budget = prefs.getDouble(_budgetKey) ?? 50000;
    _currency = prefs.getString(_currencyKey) ?? '₽';
    _nextCategoryId =
        _categories.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
    _nextExpenseId = _expenses.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
    _loaded = true;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _categoriesKey,
        jsonEncode(_categories
            .map((e) => {
                  'id': e.id,
                  ...e.toMap(),
                })
            .toList()));
    await prefs.setString(
        _expensesKey,
        jsonEncode(_expenses
            .map((e) => {
                  'id': e.id,
                  ...e.toMap(),
                })
            .toList()));
    await prefs.setDouble(_budgetKey, _budget);
    await prefs.setString(_currencyKey, _currency);
  }

  Future<List<BudgetCategory>> getCategories(
      {bool includeArchived = false}) async {
    await _ensureLoaded();
    final result =
        _categories.where((e) => includeArchived || !e.archived).toList();
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<List<Expense>> getExpenses(DateTime month) async {
    await _ensureLoaded();
    final result = _expenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
    result.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
    return result;
  }

  Future<void> saveExpense(Expense expense) async {
    await _ensureLoaded();
    final id = expense.id == 0 ? _nextExpenseId++ : expense.id;
    final saved = Expense(
        id: id,
        amount: expense.amount,
        categoryId: expense.categoryId,
        note: expense.note,
        date: expense.date);
    _expenses.removeWhere((e) => e.id == id);
    _expenses.add(saved);
    await _persist();
  }

  Future<void> deleteExpense(int id) async {
    await _ensureLoaded();
    _expenses.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> saveCategory(BudgetCategory category) async {
    await _ensureLoaded();
    final id = category.id == 0 ? _nextCategoryId++ : category.id;
    final saved = BudgetCategory(
        id: id,
        name: category.name,
        icon: category.icon,
        monthlyLimit: category.monthlyLimit,
        archived: category.archived);
    _categories.removeWhere((e) => e.id == id);
    _categories.add(saved);
    await _persist();
  }

  Future<void> archiveCategory(int id) async {
    await _ensureLoaded();
    _categories = _categories
        .map((e) => e.id == id
            ? BudgetCategory(
                id: e.id,
                name: e.name,
                icon: e.icon,
                monthlyLimit: e.monthlyLimit,
                archived: true)
            : e)
        .toList();
    await _persist();
  }

  Future<double> getMonthlyBudget() async {
    await _ensureLoaded();
    return _budget;
  }

  Future<String> getCurrency() async {
    await _ensureLoaded();
    return _currency;
  }

  Future<void> setMonthlyBudget(double amount) async {
    await _ensureLoaded();
    _budget = amount;
    await _persist();
  }

  Future<void> setCurrency(String currency) async {
    await _ensureLoaded();
    _currency = currency;
    await _persist();
  }
}
