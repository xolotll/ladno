import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/repositories/budget_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  await initializeDateFormatting('ru');
  runApp(LadnoApp(repository: BudgetRepository()));
}
