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
    final media = MediaQuery.of(context);
    final horizontalPadding = media.size.width < 360 ? 12.0 : media.size.width * 0.04;
    final verticalPadding = media.size.height * 0.02;

    return Scaffold(
      body: BlockPuzzleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding.clamp(12.0, 32.0),
              vertical: verticalPadding.clamp(12.0, 28.0),
            ),
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
        image: DecorationImage(
          image: AssetImage('assets/images/2.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color.fromARGB(80, 0, 0, 0),
            BlendMode.darken,
          ),
        ),
      ),
      child: child,
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
        final upperClamp = min(media.size.shortestSide * 0.9, 640.0);
        final lowerClamp = max(260.0, media.size.shortestSide * 0.55);
        final fallback = min(media.size.width * 0.9, upperClamp);
        final boardDimension = (base.isFinite ? base.clamp(lowerClamp, upperClamp) : fallback).toDouble();
        final board = BlockGameBoard(
          dimension: boardDimension,
          provider: blockPuzzleProvider,
          dragController: dragController,
        );
        final centeredBoard = Center(child: board);

        if (isWide) {
          return centeredBoard;
        }

        return centeredBoard;
      },
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
    final cellSize = min(context.dynamicHeight(0.035), context.dynamicWidth(0.075));
    final reservedHeight = cellSize * 5 + context.dynamicHeight(0.01);

    return SizedBox(
      height: reservedHeight,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.dynamicHeight(0.005)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: state.availablePieces
              .map(
                (piece) => Padding(
                  padding: EdgeInsets.only(right: context.dynamicHeight(0.01)),
                  child: PieceWidget(
                    piece: piece,
                    cellSize: cellSize,
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
      ),
    );
  }
}
