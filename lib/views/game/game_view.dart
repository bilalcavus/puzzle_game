import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/leaderboard_entry.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/puzzle_provider.dart';
import '../../widgets/components/app_button.dart';
import '../../widgets/components/counter_widget.dart';
import '../../widgets/components/locale_menu_button.dart';
import '../../widgets/puzzle/puzzle_board.dart';
import 'widgets/victory_dialog.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({super.key});

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  ProviderSubscription<PuzzleState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(puzzleProvider.notifier).shuffle();
    });
    _subscription = ref.listenManual<PuzzleState>(puzzleProvider, (
      previous,
      next,
    ) {
      if (next.showVictory && !(previous?.showVictory ?? false)) {
        VictoryDialog.show(
          context,
          next,
          () => ref.read(puzzleProvider.notifier).restart(),
          () => ref.read(puzzleProvider.notifier).nextLevel(),
        ).then((_) => ref.read(puzzleProvider.notifier).dismissVictory());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(puzzleProvider);
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(
            'common.level_with_number',
            namedArgs: {'level': '${puzzleState.level}'},
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: tr('common.restart'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(puzzleProvider.notifier).restart(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LocaleMenuButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : constraints.maxWidth;
            final shortestSide = min(constraints.maxWidth, availableHeight);
            final rawSize = shortestSide * (isWide ? 0.7 : 0.9);
            final boardDimension = rawSize.clamp(260.0, 520.0).toDouble();

            final board = Center(
              child: PuzzleBoard(
                puzzle: puzzleState.puzzle,
                dimension: boardDimension,
              ),
            );

            final sidePanel = _SidePanel(
              state: puzzleState,
              leaderboard: leaderboard,
              onRestart: () => ref.read(puzzleProvider.notifier).restart(),
              onNextLevel: () => ref.read(puzzleProvider.notifier).nextLevel(),
            );

            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(child: board),
                    const SizedBox(width: 24),
                    SizedBox(width: 280, child: sidePanel),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [board, const SizedBox(height: 24), sidePanel],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.state,
    required this.leaderboard,
    required this.onRestart,
    required this.onNextLevel,
  });

  final PuzzleState state;
  final AsyncValue<List<LeaderboardEntry>> leaderboard;
  final VoidCallback onRestart;
  final VoidCallback onNextLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CounterWidget(
              label: tr('common.moves'),
              value: state.moves.toString(),
            ),
            CounterWidget(label: tr('common.time'), value: state.formattedTime),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          tr('leaderboard.title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildLeaderboard(context),
        const SizedBox(height: 16),
        AppButton(label: tr('common.restart'), onPressed: onRestart),
        const SizedBox(height: 12),
        AppButton(label: tr('common.next_level'), onPressed: onNextLevel),
      ],
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    return leaderboard.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Text(tr('leaderboard.empty'));
        }
        return Column(
          children: entries
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr(
                      'leaderboard.entry',
                      namedArgs: {
                        'name': entry.name,
                        'moves': '${entry.moves}',
                      },
                    ),
                  ),
                  subtitle: Text(_formatDuration(entry.duration)),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) =>
          Text(tr('leaderboard.error', namedArgs: {'error': '$error'})),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
