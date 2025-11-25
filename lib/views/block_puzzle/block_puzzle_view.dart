import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/core/extension/sized_box.dart';

import '../../providers/block_puzzle_provider.dart';
import '../../providers/sound_provider.dart';
import '../../widgets/block/game_board.dart';
import '../../widgets/block/piece_drag_controller.dart';
import '../../widgets/block/piece_widget.dart';
import '../../widgets/block/score_panel.dart';

class BlockPuzzleGameView extends ConsumerStatefulWidget {
  const BlockPuzzleGameView({super.key});

  @override
  ConsumerState<BlockPuzzleGameView> createState() => _BlockPuzzleGameViewState();
}

class _BlockPuzzleGameViewState extends ConsumerState<BlockPuzzleGameView> {
  late final BlockDragController _dragController;

  @override
  void initState() {
    super.initState();
    _dragController = BlockDragController();
  }

  @override
  void dispose() {
    _dragController.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockPuzzleProvider);
    final notifier = ref.read(blockPuzzleProvider.notifier);

    return Scaffold(
      body: BlockPuzzleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.dynamicHeight(0.02)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScorePanel(state: state),
                context.dynamicHeight(0.02).height,
                Expanded(
                  child: BlockPuzzleBoardSection(
                    state: state,
                    onSizeChanged: notifier.changeBoardSize,
                    dragController: _dragController,
                  ),
                ),
                context.dynamicHeight(0.01).height,
                BlockPuzzlePiecesTray(
                  state: state,
                  dragController: _dragController,
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

class BlockPuzzleBackground extends StatelessWidget {
  const BlockPuzzleBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 24, 77, 55), Color(0xFF1E1F26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: context.dynamicHeight(0.04) * -0.05,
            left: context.dynamicWidth(0.7),
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/image.png',
                width: context.dynamicWidth(0.4),
              ),
            ),
          ),
          Positioned(
            top: context.dynamicHeight(0.3),
            left: context.dynamicWidth(0.15) * -0.5,
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/wind.png',
                width: context.dynamicWidth(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: context.dynamicHeight(0.01) * -1,
            right: context.dynamicWidth(0.3),
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/campfire1.png',
                width: context.dynamicWidth(0.4),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BlockPuzzleBoardSection extends StatelessWidget {
  const BlockPuzzleBoardSection({
    super.key,
    required this.state,
    required this.onSizeChanged,
    required this.dragController,
  });

  final BlockPuzzleState state;
  final ValueChanged<int> onSizeChanged;
  final BlockDragController dragController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;
        final isWide = maxWidth > 900;
        final base = isWide ? maxWidth * 1.05 : maxWidth;
        final upperClamp = min(media.size.shortestSide * 0.99, 640.0);
        final lowerClamp = 360.0;
        final fallback = min(media.size.width * 0.82, upperClamp);
        final boardDimension = (base.isFinite ? base.clamp(lowerClamp, upperClamp) : fallback).toDouble();
        final board = BlockGameBoard(
          dimension: boardDimension,
          provider: blockPuzzleProvider,
          dragController: dragController,
        );
        final sidePanel = BlockPuzzleSidePanel(
          selectedSize: state.size,
          onSizeChanged: onSizeChanged,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: board)),
              sidePanel,
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Center(child: board),
              context.dynamicHeight(0.02).height,
              sidePanel,
            ],
          ),
        );
      },
    );
  }
}

class BlockPuzzleSidePanel extends StatelessWidget {
  const BlockPuzzleSidePanel({
    super.key,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  final int selectedSize;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SegmentedButton<int>(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.green.withOpacity(0.15);
              return Colors.grey.withOpacity(0.05);
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return const BorderSide(color: Colors.blue, width: 1.5);
              return BorderSide(color: Colors.grey.withAlpha(75));
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.dynamicHeight(0.02)),
              ),
            ),
            animationDuration: const Duration(milliseconds: 200),
          ),
          segments: const [
            ButtonSegment(value: 8, label: Text('8x8')),
            ButtonSegment(value: 10, label: Text('10x10')),
          ],
          selected: {selectedSize},
          onSelectionChanged: (value) => onSizeChanged(value.first),
        ),
      ],
    );
  }
}

class BlockPuzzlePiecesTray extends ConsumerWidget {
  const BlockPuzzlePiecesTray({
    super.key,
    required this.state,
    required this.onPieceSelect,
    required this.dragController,
  });

  final BlockPuzzleState state;
  final ValueChanged<String> onPieceSelect;
  final BlockDragController dragController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: state.availablePieces
            .map(
              (piece) => Padding(
                padding: EdgeInsets.only(right: context.dynamicHeight(0.01)),
                child: PieceWidget(
                  piece: piece,
                  cellSize: context.dynamicHeight(0.03),
                  isSelected: state.selectedPieceId == piece.id,
                  disabled: state.status == BlockGameStatus.failed,
                  dragController: dragController,
                  onSelect: () => onPieceSelect(piece.id),
                  onDragStart: () {
                    ref.read(soundControllerProvider).playDrag();
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
