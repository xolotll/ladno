import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/budget_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repository});
  final BudgetRepository repository;
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  double _budget = 50000; String _currency = '₽'; int _categories = 0; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final result = await Future.wait([widget.repository.getMonthlyBudget(), widget.repository.getCurrency(), widget.repository.getCategories()]); if (!mounted) return; setState(() { _budget = result[0] as double; _currency = result[1] as String; _categories = (result[2] as List).length; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(children: [
        _setting('Общий бюджет', formatMoney(_budget, _currency), _editBudget), const Divider(height: 22),
        _setting('Валюта', _currency, _editCurrency), const Divider(height: 22),
        _setting('Категории', '$_categories', () => _showCategoriesInfo()),
      ]))),
      const SizedBox(height: 14), Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('О приложении', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Ладно — личный бюджет', style: TextStyle(color: AppColors.muted)), const SizedBox(height: 4), const Text('Данные хранятся локально в памяти браузера на этом устройстве. Регистрация не требуется. Для синхронизации между устройствами сделайте резервную копию вручную.', style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5))]))),
    ]);
  }
  Widget _setting(String title, String value, VoidCallback onTap) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))), Text(value, style: const TextStyle(color: AppColors.muted)), const SizedBox(width: 7), const Icon(Icons.chevron_right, color: AppColors.muted)])));
  Future<void> _editBudget() async { final controller = TextEditingController(text: _budget.toStringAsFixed(0)); final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Месячный бюджет'), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Сумма')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить'))])); if (ok == true) { final value = parseAmount(controller.text); if (value >= 0) { await widget.repository.setMonthlyBudget(value); await _load(); } } controller.dispose(); }
  Future<void> _editCurrency() async { final value = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(title: const Text('Валюта'), children: ['₽', '€', '\$', '£'].map((v) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, v), child: Text(v))).toList())); if (value != null) { await widget.repository.setCurrency(value); await _load(); } }
  Future<void> _showCategoriesInfo() async { await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Категории'), content: Text('Сейчас активно категорий: $_categories. Создавать и редактировать их можно на главном экране.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))])); }
}
