import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/core/extension/sized_box.dart';
import 'package:puzzle_game/providers/sound_provider.dart';

import 'block_puzzle_view.dart';
import 'level_path_view.dart';

class BlockPuzzleModeView extends ConsumerStatefulWidget {
  const BlockPuzzleModeView({super.key});

  @override
  ConsumerState<BlockPuzzleModeView> createState() => _BlockPuzzleModeViewState();
}

class _BlockPuzzleModeViewState extends ConsumerState<BlockPuzzleModeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(soundControllerProvider).ensureBackgroundMusicStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlockPuzzleBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset('assets/images/wooden_block_logo2.png', height: 300,),
                  context.dynamicHeight(0.04).height,
                  _WoodButton(
                    label: 'Adventure',
                    subtitle: 'Hedef parkuru',
                    icon: Icons.explore_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LevelPathView()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _WoodButton(
                    label: 'Classic',
                    subtitle: '8x8 & 10x10',
                    icon: Iconsax.paintbucket1,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BlockPuzzleGameView()),
                      );
                    },
                  ),
                  const Spacer(),
                  const _FooterDecoration(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 44,
          letterSpacing: 4,
          fontWeight: FontWeight.w900,
          height: 0.9,
        ) ??
        const TextStyle(fontSize: 44, fontWeight: FontWeight.w900);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WOODEN',
          style: baseStyle.copyWith(
            color: const Color(0xFFF8D08D),
            shadows: const [Shadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 8)],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'BLOCK',
          style: baseStyle.copyWith(
            color: const Color(0xFFF3B649),
            shadows: const [Shadow(color: Color(0x99000000), offset: Offset(0, 5), blurRadius: 12)],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WoodButton extends StatelessWidget {
  const _WoodButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 252, 222, 197), Color(0xFFE1B072)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), offset: Offset(0, 8), blurRadius: 16, spreadRadius: -6),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dynamicHeight(0.05),
                height: context.dynamicHeight(0.05),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF7A4A22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), offset: Offset(0, 6), blurRadius: 10),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFFFEEACC), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B2C07),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A4A22),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7A4A22)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WoodBackground extends StatelessWidget {
  const _WoodBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromARGB(255, 179, 76, 7), Color.fromARGB(255, 175, 71, 2), Color(0xFFA66A3B)],
        ),
      ),
      child: child,
    );
  }
}

class _FooterDecoration extends StatelessWidget {
  const _FooterDecoration();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 34, height: 2, color: const Color(0xFF6F4221)),
          const SizedBox(width: 12),
          const Icon(Icons.circle, size: 6, color: Color(0xFF6F4221)),
          const SizedBox(width: 12),
          Container(width: 34, height: 2, color: const Color(0xFF6F4221)),
        ],
      ),
    );
  }
}
