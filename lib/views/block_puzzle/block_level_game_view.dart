import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                if (state.levelCompleted) ...[
                  context.dynamicHeight(0.015).height,
                  FilledButton.icon(
                    onPressed: state.level >= 99 ? null : () => notifier.nextLevelChallenge(),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(state.level >= 99 ? 'Tüm leveller tamamlandı' : 'Sonraki Level'),
                  ),
                ],
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
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: goals.map(
                (goal) => Expanded(
                  child: _GoalBadge(goal: goal),
                ),
              ).toList(),
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
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
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
  const _LevelBoardSection({
    required this.state,
    required this.onNextLevel,
  });

  final BlockPuzzleState state;
  final VoidCallback onNextLevel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;
        final base = maxWidth;
        final upperClamp = min(media.size.shortestSide * 0.98, 520.0);
        final lowerClamp = 320.0;
        final fallback = min(media.size.width * 0.82, upperClamp);
        final boardDimension = (base.isFinite ? base.clamp(lowerClamp, upperClamp) : fallback).toDouble();

        return Stack(
          alignment: Alignment.center,
          children: [
            BlockGameBoard(
              dimension: boardDimension,
              provider: blockPuzzleLevelProvider,
            ),
            if (state.levelCompleted)
              _LevelCompletionOverlay(
                level: state.level,
                onNext: onNextLevel,
              ),
          ],
        );
      },
    );
  }
}

class _LevelCompletionOverlay extends StatelessWidget {
  const _LevelCompletionOverlay({required this.level, required this.onNext});

  final int level;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Level $level tamamlandı!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onNext,
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
  }
}
