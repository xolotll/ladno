import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.repository, this.expense});

  final BudgetRepository repository;
  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  List<BudgetCategory> _categories = [];
  int? _categoryId;
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount.text = widget.expense?.amount.toString() ?? '';
    _note.text = widget.expense?.note ?? '';
    _date = widget.expense?.date ?? DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await widget.repository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = list;
      _categoryId =
          widget.expense?.categoryId ?? (list.isEmpty ? null : list.first.id);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _saving = true);
    final old = widget.expense;
    await widget.repository.saveExpense(Expense(
        id: old?.id ?? 0,
        amount: parseAmount(_amount.text),
        categoryId: _categoryId!,
        note: _note.text.trim(),
        date: _date));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              widget.expense == null ? 'Новый расход' : 'Изменить расход')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(18), children: [
                const Text('Сумма',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 7),
                TextFormField(
                    controller: _amount,
                    autofocus: widget.expense == null,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: '0'),
                    validator: (v) => parseAmount(v ?? '') > 0
                        ? null
                        : 'Введите сумму больше нуля'),
                const SizedBox(height: 17),
                const Text('Категория',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 7),
                DropdownButtonFormField<int>(
                    value: _categoryId,
                    decoration: const InputDecoration(),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text('${c.icon}  ${c.name}')))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v)),
                const SizedBox(height: 17),
                const Text('Комментарий',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 7),
                TextFormField(
                    controller: _note,
                    decoration: const InputDecoration(
                        hintText: 'Например, покупки на неделю')),
                const SizedBox(height: 8),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined,
                        color: AppColors.lavender),
                    title: Text(
                        '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}'),
                    onTap: _pickDate),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Сохраняем…' : 'Сохранить')),
                if (widget.expense != null)
                  TextButton(
                      onPressed: _delete,
                      child: const Text('Удалить расход',
                          style: TextStyle(color: AppColors.danger))),
              ])));

  Future<void> _pickDate() async {
    final value = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (value != null) setState(() => _date = value);
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: const Text('Удалить расход?'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Отмена')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Удалить'))
            ]));
    if (yes == true) {
      await widget.repository.deleteExpense(widget.expense!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }
}
