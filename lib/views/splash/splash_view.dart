import 'dart:async';

import 'package:flutter/material.dart';
import 'package:puzzle_game/app/startup_service.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/core/extension/sized_box.dart';
import '../block_puzzle/block_mode_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _startApp();
    _fallbackTimer = Timer(const Duration(seconds: 10), _goToHome);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _startApp() async {
    final startTime = DateTime.now();
    await StartupService.instance.prepare();
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining.isNegative) {
      _goToHome();
      return;
    }
    await Future<void>.delayed(remaining);
    _goToHome();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BlockPuzzleModeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/wooden_block_logo2.png',
                width: 220,
                fit: BoxFit.contain,
              ),
              context.dynamicHeight(0.04).height,
              // CircularProgressIndicator(color: Colors.green.shade900)
            ],
          ),
        ),
      ),
    );
  }
}
