import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen(
      {super.key, required this.repository, required this.month});

  final BudgetRepository repository;
  final DateTime month;

  @override State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<BudgetCategory> _categories = [];
  List<Expense> _expenses = [];
  String _currency = '₽';
  bool _loading = true;
  static const _colors = [
    AppColors.lavender,
    Color(0xFFB9A5E8),
    Color(0xFFD5C9EF),
    Color(0xFF7960B6),
    Color(0xFFE3DAF3),
    Color(0xFF9DB9AA)
  ];

  @override void initState() {
    super.initState();
    _load();
  }

  @override void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) _load();
  }

  Future<void> _load() async {
    final result = await Future.wait([
      widget.repository.getCategories(),
      widget.repository.getExpenses(widget.month),
      widget.repository.getCurrency()
    ]);
    if (!mounted) return;
    setState(() {
      _categories = result[0] as List<BudgetCategory>;
      _expenses = result[1] as List<Expense>;
      _currency = result[2] as String;
      _loading = false;
    });
  }

  double _spent(int id) =>
      _expenses.where((e) => e.categoryId == id).fold(
          0, (s, e) => s + e.amount);

  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final total = _expenses.fold<double>(0, (s, e) => s + e.amount);
    final rows = _categories
        .map((c) => (category: c, amount: _spent(c.id)))
        .where((r) => r.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final days = DateTime(widget.month.year, widget.month.month + 1, 0).day;
    return RefreshIndicator(onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          Card(child: Padding(padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Всего потрачено',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(formatMoney(total, _currency), style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 13),
                    Row(children: [
                      Expanded(
                          child: _metric('Операций', '${_expenses.length}')),
                      Expanded(child: _metric('В среднем за день',
                          formatMoney(total / days, _currency)))
                    ])
                  ]))),
          const Padding(padding: EdgeInsets.fromLTRB(3, 18, 3, 9),
              child: Text('Расходы по категориям',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          if (rows.isEmpty) const Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text(
                  'Добавьте расходы, чтобы увидеть статистику',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted)))))
          else
            Card(child: Padding(padding: const EdgeInsets.all(17),
                child: Column(children: [
                  SizedBox(height: 190,
                      child: CustomPaint(size: const Size(double.infinity, 190),
                          painter: _DonutPainter(values: rows.map((r) =>
                          r.amount).toList(),
                              colors: _colors,
                              total: total))),
                  const SizedBox(height: 12),
                  ...rows
                      .asMap()
                      .entries
                      .map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Padding(padding: const EdgeInsets.symmetric(
                        vertical: 7), child: Row(children: [
                      Container(width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                              color: _colors[i % _colors.length],
                              borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 9),
                      Expanded(child: Text(
                          '${row.category.icon} ${row.category.name}')),
                      Text('${(row.amount / total * 100).round()}%',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                      const SizedBox(width: 10),
                      Text(formatMoney(row.amount, _currency),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12))
                    ]));
                  })
                ]))),
          const Padding(padding: EdgeInsets.fromLTRB(3, 18, 3, 9),
              child: Text('Лимиты категорий',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          ..._categories.map((c) {
            final spent = _spent(c.id);
            final limit = c.monthlyLimit;
            return Card(child: Padding(padding: const EdgeInsets.all(15),
                child: Column(children: [
                  Row(children: [
                    Text('${c.icon} ${c.name}', style: const TextStyle(
                        fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${formatMoney(spent, _currency)} / ${formatMoney(
                        limit, _currency)}', style: const TextStyle(
                        fontSize: 11))
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: limit <= 0
                          ? 0
                          : (spent / limit).clamp(0, 1),
                          minHeight: 6,
                          color: AppColors.lavender,
                          backgroundColor: AppColors.lavenderLight))
                ])));
          }),
        ]));
  }

  Widget _metric(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
          ]);
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(
      {required this.values, required this.colors, required this.total});

  final List<double> values;
  final List<Color> colors;
  final double total;

  @override void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * .38;
    var start = -1.57079632679;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 6.28318530718;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius), start, sweep, false,
          paint);
      start += sweep;
    }
    final text = TextPainter(text: TextSpan(
        text: NumberFormat.compact(locale: 'ru').format(total),
        style: const TextStyle(
            color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 20)),
    )
      ..layout();
    text.paint(canvas,
        Offset(center.dx - text.width / 2, center.dy - text.height / 2));
  }

  @override bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.values != values;
}
