import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/expense.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.categories, required this.currency, required this.onTap});
  final Expense expense; final List<BudgetCategory> categories; final String currency; final VoidCallback onTap;
  @override Widget build(BuildContext context) {
    final matches = categories.where((c) => c.id == expense.categoryId);
    final category = matches.isEmpty ? null : matches.first;
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), child: Row(children: [
      Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.lavenderLight, borderRadius: BorderRadius.circular(14)), child: Text(category?.icon ?? '◦', style: const TextStyle(fontSize: 19))),
      const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(expense.note.isEmpty ? (category?.name ?? 'Расход') : expense.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('${category?.name ?? 'Архивная категория'} · ${formatShortDate(expense.date)}', style: const TextStyle(color: AppColors.muted, fontSize: 11))])),
      Text('−${formatMoney(expense.amount, currency)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ])));
  }
}
