import 'package:flutter/material.dart';
import 'package:puzzle_game/views/splash/splash_view.dart';
import 'app_theme.dart';

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashView(),
    );
  }
}
