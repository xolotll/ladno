import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/budget_repository.dart';
import 'features/shell/app_shell.dart';

class LadnoApp extends StatelessWidget {
  const LadnoApp({super.key, required this.repository});
  final BudgetRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ладно',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [Locale('ru', 'RU')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AppShell(repository: repository),
      );
}
