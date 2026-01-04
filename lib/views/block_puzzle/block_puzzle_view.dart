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
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding.clamp(12.0, 32.0), vertical: verticalPadding.clamp(12.0, 28.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScorePanel(state: state),
                context.dynamicHeight(0.02).height,
                Expanded(
                  child: _BlockPuzzleBoardWithTray(
                    state: state,
                    dragController: _dragController,
                    onPieceSelect: (pieceId) {
                      HapticFeedback.selectionClick();
                      notifier.selectPiece(pieceId);
                    },
                  ),
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
        image: DecorationImage(image: AssetImage('assets/images/2.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color.fromARGB(80, 0, 0, 0), BlendMode.darken)),
      ),
      child: child,
    );
  }
}

class BlockPuzzleBoardSection extends StatelessWidget {
  const BlockPuzzleBoardSection({super.key, required this.state, required this.onSizeChanged, required this.dragController});

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
        final board = BlockGameBoard(dimension: boardDimension, provider: blockPuzzleProvider, dragController: dragController);
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
    this.locked = false,
    this.extraHitSlopTop = 0,
    this.alignBottom = false,
  });

  final BlockPuzzleState state;
  final ValueChanged<String> onPieceSelect;
  final BlockDragController dragController;
  final bool locked;
  final double extraHitSlopTop;
  final bool alignBottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool disablePieces = locked || state.status == BlockGameStatus.failed;
    final maxCellSize = min(context.dynamicHeight(0.035), context.dynamicWidth(0.075));
    final fixedTrayHeight = maxCellSize * 5 + context.dynamicHeight(0.01);
    final trayHeight = fixedTrayHeight + extraHitSlopTop;

    return IgnorePointer(
      ignoring: disablePieces,
      child: Opacity(
        opacity: disablePieces ? 0.6 : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = context.dynamicHeight(0.01);
            final piecePadding = context.dynamicHeight(0.010) * 2;
            final horizontalPadding = context.dynamicHeight(0.005) * 2;
            final pieceCount = state.availablePieces.length;
            final totalBlockWidth = state.availablePieces.fold<int>(0, (sum, piece) => sum + piece.width);
            final totalSpacing = pieceCount > 1 ? spacing * (pieceCount - 1) : 0.0;
            final totalPadding = pieceCount > 0 ? (8.0 + piecePadding) * pieceCount : 0.0;
            final safetyPadding = pieceCount > 0 ? 2.0 * pieceCount : 0.0;
            final availableWidth = max(0.0, constraints.maxWidth - horizontalPadding - totalSpacing - totalPadding - safetyPadding);
            final fitCellSize = totalBlockWidth > 0 ? (availableWidth / totalBlockWidth).clamp(10.0, maxCellSize) : maxCellSize;
            final contentPadding = context.dynamicHeight(0.010);
            final row = Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(state.availablePieces.length, (index) {
                final piece = state.availablePieces[index];
                final isLast = index == state.availablePieces.length - 1;
                final visualPieceHeight = (piece.height * fitCellSize) + 8 + (contentPadding * 2);
                final hitSlopTop = max(0.0, trayHeight - visualPieceHeight);
                return Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : spacing),
                  child: PieceWidget(
                    piece: piece,
                    cellSize: fitCellSize,
                    isSelected: state.selectedPieceId == piece.id,
                    disabled: disablePieces,
                    hitSlopTop: hitSlopTop,
                    dragController: dragController,
                    onSelect: () => onPieceSelect(piece.id),
                    onDragStart: () {
                      ref.read(soundControllerProvider).playDrag();
                    },
                  ),
                );
              }),
            );
            final content = alignBottom
                ? Align(alignment: Alignment.bottomCenter, child: row)
                : Center(child: row);

            return SizedBox(
              height: trayHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.dynamicHeight(0.005)),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BlockPuzzleBoardWithTray extends ConsumerWidget {
  const _BlockPuzzleBoardWithTray({
    required this.state,
    required this.dragController,
    required this.onPieceSelect,
  });

  final BlockPuzzleState state;
  final BlockDragController dragController;
  final ValueChanged<String> onPieceSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        final maxCellSize = min(context.dynamicHeight(0.035), context.dynamicWidth(0.075));
        final fixedTrayHeight = maxCellSize * 5 + context.dynamicHeight(0.01);
        final traySpacing = context.dynamicHeight(0.01);
        final stackHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : media.size.height;
        final availableForBoard = max(0.0, stackHeight - fixedTrayHeight - traySpacing);
        final boardTop = max(0.0, (availableForBoard - boardDimension) / 2);
        final boardBottom = boardTop + boardDimension;
        final trayTop = stackHeight - fixedTrayHeight;
        final extraHitSlopTop = max(0.0, trayTop - boardBottom);

        return Stack(
          children: [
            Positioned(
              top: boardTop,
              left: 0,
              right: 0,
              child: Center(
                child: BlockGameBoard(
                  dimension: boardDimension,
                  provider: blockPuzzleProvider,
                  dragController: dragController,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlockPuzzlePiecesTray(
                state: state,
                dragController: dragController,
                onPieceSelect: onPieceSelect,
                extraHitSlopTop: extraHitSlopTop,
                alignBottom: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
