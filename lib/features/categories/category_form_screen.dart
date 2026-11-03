import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/category.dart';

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen(
      {super.key, required this.repository, this.category});

  final BudgetRepository repository;
  final BudgetCategory? category;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _name = TextEditingController();
  final _limit = TextEditingController();
  final _form = GlobalKey<FormState>();
  static const _icons = [
    '🛒',
    '🚕',
    '🏠',
    '☕',
    '🛍️',
    '💊',
    '👗',
    '✈️',
    '🐾',
    '🎁',
    '🍿',
    '💅',
    '🥀',
    '🤫',
    '🫦',
    '🧋'
  ];
  String _icon = '🛒';
  String _currency = '₽';

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name.text = c?.name ?? '';
    _limit.text = c?.monthlyLimit.toString() ?? '';
    _icon = c?.icon ?? _icons.first;
    widget.repository.getCurrency().then((v) {
      if (mounted) setState(() => _currency = v);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final old = widget.category;
    await widget.repository.saveCategory(BudgetCategory(
        id: old?.id ?? 0,
        name: _name.text.trim(),
        icon: _icon,
        monthlyLimit: parseAmount(_limit.text)));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.category == null
              ? 'Новая категория'
              : 'Изменить категорию')),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(18), children: [
            TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Название категории'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Введите название'
                    : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _limit,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: 'Месячный лимит ($_currency)')),
            const SizedBox(height: 18),
            const Text('Иконка', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons
                    .map((icon) => ChoiceChip(
                        label: Text(icon, style: const TextStyle(fontSize: 19)),
                        selected: _icon == icon,
                        onSelected: (_) => setState(() => _icon = icon)))
                    .toList()),
            const SizedBox(height: 25),
            FilledButton(onPressed: _save, child: const Text('Сохранить')),
            if (widget.category != null)
              TextButton(
                  onPressed: _archive,
                  child: const Text('Архивировать категорию',
                      style: TextStyle(color: AppColors.danger))),
          ])));

  Future<void> _archive() async {
    await widget.repository.archiveCategory(widget.category!.id);
    if (mounted) Navigator.pop(context, true);
  }
}
