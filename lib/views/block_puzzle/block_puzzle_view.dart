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
                  child: BlockPuzzleBoardSection(state: state, onSizeChanged: notifier.changeBoardSize, dragController: _dragController),
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
  const BlockPuzzlePiecesTray({super.key, required this.state, required this.onPieceSelect, required this.dragController, this.locked = false});

  final BlockPuzzleState state;
  final ValueChanged<String> onPieceSelect;
  final BlockDragController dragController;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellSize = min(context.dynamicHeight(0.035), context.dynamicWidth(0.075));
    // Bir parça seçildiğinde boyutu büyüyeceği için yüksekliği biraz artır.
    final reservedHeight = cellSize * 5.4 + context.dynamicHeight(0.01);
    final bool disablePieces = locked || state.status == BlockGameStatus.failed;

    return IgnorePointer(
      ignoring: disablePieces,
      child: Opacity(
        opacity: disablePieces ? 0.6 : 1,
        child: SizedBox(
          height: reservedHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.dynamicHeight(0.01)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double unselectedScale = 0.72;
                final pieces = state.availablePieces;
                final slotCount = max(3, pieces.length);
                // Slot boyutlarını dar tut ve toplam genişliği ekrana göre ölçekle.
                final slotWidth = cellSize * 3.6;
                final slotHeight = cellSize * 3.6;
                final slotSpacing = context.dynamicHeight(0.006);
                final totalWidth = slotWidth * slotCount + slotSpacing * (slotCount - 1);

                List<Widget> buildSlot(int index) {
                  if (index >= pieces.length) {
                    return [SizedBox(width: slotWidth, height: slotHeight)];
                  }
                  final piece = pieces[index];
                  final isSelected = state.selectedPieceId == piece.id;
                  final scale = isSelected ? 1.0 : unselectedScale;
                  return [
                    SizedBox(
                      width: slotWidth,
                      height: slotHeight,
                      child: Center(
                        child: Transform.scale(
                          scale: scale,
                          child: PieceWidget(
                            piece: piece,
                            cellSize: cellSize,
                            isSelected: isSelected,
                            disabled: disablePieces,
                            dragController: dragController,
                            onSelect: () => onPieceSelect(piece.id),
                            onDragStart: () {
                              ref.read(soundControllerProvider).playDrag();
                            },
                          ),
                        ),
                      ),
                    ),
                  ];
                }

                return LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final scale = totalWidth > innerConstraints.maxWidth && innerConstraints.maxWidth.isFinite ? innerConstraints.maxWidth / totalWidth : 1.0;
                    return Center(
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: reservedHeight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List<Widget>.generate(slotCount, (index) {
                              final slot = buildSlot(index).first;
                              if (index == slotCount - 1) return slot;
                              return Padding(
                                padding: EdgeInsets.only(right: slotSpacing),
                                child: slot,
                              );
                            }),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
