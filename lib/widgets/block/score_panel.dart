import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/providers/sound_provider.dart';
import '../../providers/block_puzzle_provider.dart';
import '../components/locale_menu_button.dart';

class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key, required this.state});

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
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(context, tr('common.score'), state.score.toString()),
                    _stat(
                      context,
                      tr('common.lines'),
                      state.totalLinesCleared.toString(),
                    ),
                    _stat(context, tr('common.best'), state.bestScore.toString()),
                  ],
                ),
              ),
              SizedBox(width: context.dynamicWidth(0.06)),
              _WoodIconButton(
                onPressed: () =>
                    ref.read(blockPuzzleProvider.notifier).restart(),
                icon: Iconsax.refresh,
              ),
              SizedBox(width: context.dynamicWidth(0.02)),
              _WoodIconButton(
                icon: Iconsax.setting,
                onPressed: () => showSettingsSheet(context, ref),
              ),
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
                        tr('common.settings'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SwitchListTile.adaptive(
                    value: settings.effectsEnabled,
                    onChanged: notifier.setEffectsEnabled,
                    title: Text(
                      tr('common.effects'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      tr('common.effects_desc'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    activeColor: Colors.tealAccent,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr('common.language'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      tr('common.language_hint'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: LocaleMenuButton(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
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
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
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

class _WoodIconButton extends StatelessWidget {
  const _WoodIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: context.dynamicHeight(0.05),
        height: context.dynamicHeight(0.05),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFFE7BC7D), Color(0xFFD59A55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF8D581E), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: const Color(0xFF7A3D1C),
            size: context.dynamicHeight(0.03),
          ),
        ),
      ),
    );
  }
}
