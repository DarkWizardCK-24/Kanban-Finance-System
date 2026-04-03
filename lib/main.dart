import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kanban_finance_system/firebase_options.dart';
import 'constants/app_theme.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KanbanFinanceApp());
}

class KanbanFinanceApp extends StatelessWidget {
  const KanbanFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}