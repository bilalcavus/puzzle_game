import 'dart:math';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/providers/sound_provider.dart';
import 'package:puzzle_game/views/block_puzzle/block_puzzle_view.dart';
import 'package:puzzle_game/widgets/block/score_panel.dart';
import '../../core/extension/dynamic_size.dart';
import '../../core/extension/sized_box.dart';
import '../../models/block_level_models.dart';
import '../../providers/block_puzzle_level_provider.dart';
import '../../providers/block_puzzle_provider.dart';
import '../../widgets/block/game_board.dart';
import '../../widgets/components/locale_menu_button.dart';

class BlockPuzzleLevelGameView extends ConsumerWidget {
  const BlockPuzzleLevelGameView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockPuzzleLevelProvider);
    final notifier = ref.read(blockPuzzleLevelProvider.notifier);

    return Scaffold(
      body: BlockPuzzleBackground(
        child: SafeArea(
          child: Padding(
            padding: context.padding.low,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LevelHeader(
                  level: state.level,
                  goals: state.levelGoals,
                  onRestart: () => notifier.restart(),
                  ref: ref,
                ),
                context.dynamicHeight(0.02).height,
                Expanded(
                  child: _LevelBoardSection(
                    state: state,
                    onNextLevel: () => notifier.nextLevelChallenge(),
                  ),
                ),
                context.dynamicHeight(0.01).height,
                BlockPuzzlePiecesTray(
                  state: state,
                  onPieceSelect: (pieceId) {
                    HapticFeedback.selectionClick();
                    notifier.selectPiece(pieceId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.level,
    required this.goals,
    required this.onRestart,
    required this.ref,
  });

  final int level;
  final List<BlockLevelGoal> goals;
  final VoidCallback onRestart;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: context.padding.horizontalLow,
              child: Text(
                tr('common.level_with_number', namedArgs: {'level': '$level'}),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: tr('common.restart'),
              onPressed: onRestart,
              icon: const Icon(Iconsax.refresh, color: Colors.white),
            ),
            SettingsButton(onPressed: () => showSettingsSheet(context, ref)),
          ],
        ),
        context.dynamicHeight(0.01).height,
        Row(
          children: goals
              .map((goal) => Expanded(child: _GoalBadge(goal: goal)))
              .toList(),
        ),
      ],
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
                    value: settings.musicEnabled,
                    onChanged: notifier.setMusicEnabled,
                    title: Text(
                      tr('common.background_music'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      tr('common.background_music_desc'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    activeColor: Colors.tealAccent,
                  ),
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
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({required this.goal});

  final BlockLevelGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset(
          goal.token.asset,
          width: context.dynamicWidth(0.2),
          height: context.dynamicHeight(0.05),
        ),
        Text(
          'block_level.tokens.${goal.token.name}'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        context.dynamicHeight(0.01).height,
        Text(
          '${goal.remaining}/${goal.required}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LevelBoardSection extends StatelessWidget {
  const _LevelBoardSection({required this.state, required this.onNextLevel});

  final BlockPuzzleState state;
  final VoidCallback onNextLevel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;
        final base = maxWidth;
        final upperClamp = min(media.size.shortestSide * 0.98, 520.0);
        final lowerClamp = 320.0;
        final fallback = min(media.size.width * 0.82, upperClamp);
        final boardDimension =
            (base.isFinite ? base.clamp(lowerClamp, upperClamp) : fallback)
                .toDouble();

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            IgnorePointer(
              ignoring: state.levelCompleted,
              child: BlockGameBoard(
                dimension: boardDimension,
                provider: blockPuzzleLevelProvider,
              ),
            ),
            if (state.levelCompleted)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.9, sigmaY: 1.9),
                  child: SizedBox.shrink(),
                ),
              ),
            if (state.levelCompleted)
              _LevelCompletionOverlay(
                level: state.level,
                onNext: onNextLevel,
                goals: state.levelGoals,
              ),
          ],
        );
      },
    );
  }
}

class _LevelCompletionOverlay extends StatelessWidget {
  const _LevelCompletionOverlay({
    required this.level,
    required this.onNext,
    required this.goals,
  });

  final int level;
  final VoidCallback onNext;
  final List<BlockLevelGoal> goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              14,
              57,
              13,
            ).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 25,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < goals.length; i++) ...[
                if (i > 0) const SizedBox(width: 22),
                _CompletionTokenBadge(goal: goals[i]),
              ],
            ],
          ),
        ),
        context.dynamicHeight(0.02).height,
        Text(
          tr('common.well_done'),
          style: theme.textTheme.displaySmall?.copyWith(
            color: const Color.fromARGB(255, 255, 154, 154),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
          ),
        ),
        context.dynamicHeight(0.02).height,
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 5, 160, 20),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 10,
            shadowColor: Colors.black45,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: context.dynamicHeight(0.03),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                tr('common.next_level'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletionTokenBadge extends StatelessWidget {
  const _CompletionTokenBadge({required this.goal});

  final BlockLevelGoal goal;

  @override
  Widget build(BuildContext context) {
    final bool completed = goal.isComplete;
    final Color accent = goal.token.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.dynamicHeight(0.08),
          height: context.dynamicHeight(0.08),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                accent.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: context.padding.low,
            child: Image.asset(goal.token.asset),
          ),
        ),
        context.dynamicHeight(0.015).height,
        Icon(
          Icons.check_rounded,
          color: completed ? const Color(0xFF63E76C) : Colors.white30,
          size: context.dynamicHeight(0.03),
        ),
      ],
    );
  }
}
