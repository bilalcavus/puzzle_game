import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/block_puzzle_provider.dart';
import '../../widgets/block/game_board.dart';
import '../../widgets/block/piece_widget.dart';
import '../../widgets/block/score_panel.dart';

class BlockPuzzleGameView extends ConsumerWidget {
  const BlockPuzzleGameView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockPuzzleProvider);
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Wooden Blocks', style: Theme.of(context).textTheme.titleLarge?.copyWith(
      //     fontWeight: FontWeight.bold
      //   )),
      //   backgroundColor: Color.fromARGB(255, 18, 60, 55),
      //   leading:  IconButton(
      //     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      //   actions: [
      //     IconButton(
      //     icon: const Icon(Icons.map, color: Colors.white),
      //     tooltip: 'Adventure Mode',
      //     onPressed: () => Navigator.of(context).push(
      //       MaterialPageRoute(builder: (_) => const AdventureModeView()),
      //     ),
      //   ),
      //   ],
      // ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF184D47), Color(0xFF1E1F26)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              left: -10,
              child: Icon(Icons.eco, size: 140, color: Colors.greenAccent.withValues(alpha: 0.2)),
            ),
            Positioned(
              bottom: -30,
              right: -20,
              child: Icon(Icons.eco, size: 120, color: Colors.amber.withValues(alpha: 0.2)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    
                   
                    ScorePanel(state: state),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final media = MediaQuery.of(context);
                          final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;
                          final isWide = maxWidth > 900;
                          final base = isWide ? maxWidth * 1 : maxWidth;
                          final boardDimension = (base.isFinite ? base.clamp(320.0, min(media.size.shortestSide * 0.95, 580.0)) : min(media.size.width * 0.75, 520.0)).toDouble();
                          final board = BlockGameBoard(dimension: boardDimension);
                          final side = _buildSidePanel(context, ref, state);
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Center(child: board)),
                                SizedBox(width: 320, child: side),
                              ],
                            );
                          }
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                Center(child: board),
                                const SizedBox(height: 20),
                                side,
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PiecesTray(state: state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeader(BuildContext context) {
  //   return Row(
  //     children: [
  //       IconButton(
  //         icon: const Icon(Icons.arrow_back, color: Colors.white),
  //         onPressed: () => Navigator.of(context).pop(),
  //       ),
  //       const Spacer(),
  //       // IconButton(
  //       //   icon: const Icon(Icons.emoji_events, color: Colors.white),
  //       //   tooltip: 'Leaderboard',
  //       //   onPressed: () => Navigator.of(context).push(
  //       //     MaterialPageRoute(builder: (_) => const BlockLeaderboardView()),
  //       //   ),
  //       // ),
  //       IconButton(
  //         icon: const Icon(Icons.map, color: Colors.white),
  //         tooltip: 'Adventure Mode',
  //         onPressed: () => Navigator.of(context).push(
  //           MaterialPageRoute(builder: (_) => const AdventureModeView()),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSidePanel(BuildContext context, WidgetRef ref, BlockPuzzleState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 8, label: Text('8x8')),
            ButtonSegment(value: 10, label: Text('10x10')),
          ],
          selected: {state.size},
          onSelectionChanged: (value) => ref.read(blockPuzzleProvider.notifier).changeBoardSize(value.first),
        ),

        if (state.status == BlockGameStatus.failed) ...[
          const SizedBox(height: 16),
          Text('No fitting spots left. Restart to continue your streak.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent)),
          IconButton(onPressed: () => ref.read(blockPuzzleProvider.notifier).restart(), icon: Icon(Iconsax.refresh)),
        ],
      ],
    );
  }
}

class _PiecesTray extends ConsumerWidget {
  const _PiecesTray({required this.state});

  final BlockPuzzleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(blockPuzzleProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: state.availablePieces
                .map(
                  (piece) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PieceWidget(
                      piece: piece,
                      cellSize: 24,
                      isSelected: state.selectedPieceId == piece.id,
                      disabled: state.status == BlockGameStatus.failed,
                      onSelect: () {
                        HapticFeedback.selectionClick();
                        notifier.selectPiece(piece.id);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (state.selectedPieceId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Tap a piece, then touch the board to place it. Long-press to drag directly.', style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
