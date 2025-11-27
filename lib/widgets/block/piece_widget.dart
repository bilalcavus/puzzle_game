import 'package:flutter/material.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';

import '../../models/piece_model.dart';
import 'block_tile.dart';
import 'piece_drag_controller.dart';
import 'piece_drag_constants.dart';

class PieceWidget extends StatelessWidget {
  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.onSelect,
    this.onDragStart,
    this.dragController,
    this.isSelected = false,
    this.disabled = false,
  });

  final PieceModel piece;
  final double cellSize;
  final VoidCallback onSelect;
  final VoidCallback? onDragStart;
  final BlockDragController? dragController;
  final bool isSelected;
  final bool disabled;
  static const double _dragFeedbackScale = 1.4;
  static const double _liftDistance = 100;

  @override
  Widget build(BuildContext context) {
    final footprintWidth = (piece.width * cellSize) + 8;
    final footprintHeight = (piece.height * cellSize) + 8;
    final liftTarget = isSelected ? -_liftDistance : 0.0;
    final dragCellSize = cellSize * _dragFeedbackScale;
    final dragWidth = (piece.width * dragCellSize) + 8;
    final dragHeight = (piece.height * dragCellSize) + 8;
    final content = _buildContent(footprintWidth, footprintHeight);
    final child = Opacity(
      opacity: disabled ? 0.4 : 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: liftTarget),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(context.dynamicHeight(0.015)),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
              width: 1,
            ),
          ),
          child: content,
        ),
        builder: (context, value, animatedChild) {
          return Transform.translate(
            offset: Offset(0, value),
            transformHitTests: false,
            child: animatedChild,
          );
        },
      ),
    );

    if (disabled) {
      return child;
    }

    return LongPressDraggable<PieceModel>(
      // Keep a minimal hold so taps don't trigger; effectively instant drag.
      delay: const Duration(milliseconds: 60),
      hapticFeedbackOnStart: true,
      data: piece,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          // Visually lift the piece; keeps drag geometry anchored to the finger.
          offset: const Offset(0, -kPieceDragPointerYOffset),
          child: _buildContent(
            dragWidth,
            dragHeight,
            feedback: true,
            cellSizeOverride: dragCellSize,
          ),
        ),
      ),
      // Do not leave a ghost copy in the tray while dragging.
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () {
        onDragStart?.call();
        if (!isSelected) {
          onSelect(); // Select so board drops can succeed during drag.
        }
      },
      onDragUpdate: (details) => dragController?.updateHover(piece, details.globalPosition),
      // Only allow dragging for visual feedback; always snap back on release.
      onDragEnd: (details) {
        if (details.wasAccepted) {
          dragController?.cancelHover();
          return;
        }
        // If no target accepted, let the board try to place based on final offset.
        dragController?.completeDrop(piece, details.offset);
        if (isSelected) {
          onSelect(); // Clear lift state so the piece returns to its slot.
        }
      },
      onDraggableCanceled: (_, __) => dragController?.cancelHover(),
      onDragCompleted: () => dragController?.cancelHover(),
      child: child,
    );
  }

  Widget _buildContent(double width, double height, {bool feedback = false, double? cellSizeOverride}) {
    final tileSize = cellSizeOverride ?? cellSize;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: piece.blocks
            .map(
              (block) => Positioned(
                top: block.rowOffset * tileSize,
                left: block.colOffset * tileSize,
                child: BlockTile(
                  size: tileSize,
                  color: piece.color,
                  pulse: !feedback && isSelected,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
