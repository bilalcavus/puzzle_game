import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/views/block_puzzle/block_puzzle_view.dart';
import '../../core/extension/dynamic_size.dart';
import '../../core/extension/sized_box.dart';
import '../../models/block_level_models.dart';
import '../../providers/block_puzzle_level_provider.dart';
import '../../providers/block_puzzle_provider.dart';
import '../../widgets/block/game_board.dart';

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
            padding: EdgeInsets.all(context.dynamicHeight(0.02)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LevelHeader(
                  level: state.level,
                  goals: state.levelGoals,
                  onRestart: () => notifier.restart(),
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
  });

  final int level;
  final List<BlockLevelGoal> goals;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: 'Yeniden başlat',
              onPressed: onRestart,
              icon: const Icon(Iconsax.refresh, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: goals
              .map((goal) => Expanded(child: _GoalBadge(goal: goal)))
              .toList(),
        ),
      ],
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
        Image.asset(goal.token.asset, width: 32, height: 32),
        Text(
          goal.token.label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        context.dynamicHeight(0.01).height,
        Text(
          '${goal.remaining}/${goal.required}',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
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
                  child: SizedBox.shrink()
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
            color: const Color.fromARGB(255, 10, 42, 9).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.black.withValues(alpha: 0.45), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 18)),
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
          'Well Done!',
          style: theme.textTheme.displaySmall?.copyWith(
            color: const Color(0xFFFFE29A),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
          ),
        ),
        context.dynamicHeight(0.02).height,
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 126, 66),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 10,
            shadowColor: Colors.black45,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, size: context.dynamicHeight(0.03), color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Next Level',
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
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                accent.withValues(alpha: 0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(goal.token.asset),
          ),
        ),
        const SizedBox(height: 6),
        Icon(
          Icons.check_rounded,
          color: completed ? const Color(0xFF63E76C) : Colors.white30,
          size: 22,
        ),
      ],
    );
  }
}
