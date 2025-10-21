import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_menu/main_menu_page.dart';
import 'widgets/debug_overlay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reamu - Music Training',
      theme: AppTheme.darkTheme,
      home: const DebugOverlay(child: MainMenuPage()),
      debugShowCheckedModeBanner: false,
    );
  }
}
