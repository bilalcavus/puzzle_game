import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/providers/sound_provider.dart';
import '../../providers/block_puzzle_provider.dart';

class ScorePanel extends ConsumerWidget {
  const ScorePanel({
    super.key,
    required this.state,
  });

  final BlockPuzzleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: EdgeInsets.all(context.dynamicHeight(0.015)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(context, 'Score', state.score.toString()),
              _stat(context, 'Lines', state.totalLinesCleared.toString()),
              _stat(context, 'Best', state.bestScore.toString()),
              IconButton(onPressed: () => ref.read(blockPuzzleProvider.notifier).restart(), icon: Icon(Iconsax.refresh)),
              SettingsButton(onPressed: () => showSettingsSheet(context, ref))
            ],
          ),
        ),
      ),
    );
  }

  void showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101315),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final settings = sheetRef.watch(soundSettingsProvider);
            final notifier = sheetRef.read(soundSettingsProvider.notifier);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.setting, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Ayarlar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile.adaptive(
                    value: settings.musicEnabled,
                    onChanged: notifier.setMusicEnabled,
                    title: const Text('Arka plan müziği', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Doğa sesli müzik sürekli oynasın', style: TextStyle(color: Colors.white70)),
                    activeColor: Colors.tealAccent,
                  ),
                  SwitchListTile.adaptive(
                    value: settings.effectsEnabled,
                    onChanged: notifier.setEffectsEnabled,
                    title: const Text('Efekt sesleri', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Hamle ve başarı seslerini aç/kapat', style: TextStyle(color: Colors.white70)),
                    activeColor: Colors.tealAccent,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Iconsax.setting, color: Colors.white),
        tooltip: 'Ayarlar',
        onPressed: onPressed,
      ),
    );
  }
}