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
    this.hitSlopTop = 0,
  });

  final PieceModel piece;
  final double cellSize;
  final VoidCallback onSelect;
  final VoidCallback? onDragStart;
  final BlockDragController? dragController;
  final bool isSelected;
  final bool disabled;
  final double hitSlopTop;
  static const double _dragFeedbackScale = 1.5;
  static const double _liftDistance = 100;

  @override
  Widget build(BuildContext context) {
    final contentPadding = context.dynamicHeight(0.010);
    final footprintWidth = (piece.width * cellSize) + 8;
    final footprintHeight = (piece.height * cellSize) + 8;
    final visualWidth = footprintWidth + (contentPadding * 2);
    final visualHeight = footprintHeight + (contentPadding * 2);
    final liftOffsetY = isSelected ? -_liftDistance : 0.0;
    final dragCellSize = cellSize * _dragFeedbackScale;
    final dragWidth = (piece.width * dragCellSize) + 8;
    final dragHeight = (piece.height * dragCellSize) + 8;
    final content = _buildContent(footprintWidth, footprintHeight);
    final baseChild = Opacity(
      opacity: disabled ? 0.4 : 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: liftOffsetY),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(contentPadding), // less padding => larger visible piece
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent, width: 1),
          ),
          child: content,
        ),
        builder: (context, value, animatedChild) {
          return Transform.translate(offset: Offset(0, value), transformHitTests: false, child: animatedChild);
        },
      ),
    );
    final child = _wrapWithHitArea(baseChild, visualWidth, visualHeight);

    if (disabled) {
      return child;
    }

    // Preserve tray layout during drag so the board doesn't shift when a piece is lifted.
    final placeholderWhileDragging = IgnorePointer(child: Opacity(opacity: 0, child: child));

    final dragAnchorStrategy = hitSlopTop > 0
        ? (Draggable<Object> draggable, BuildContext context, Offset position) {
            final renderBox = context.findRenderObject() as RenderBox?;
            final width = renderBox?.size.width ?? visualWidth;
            // Keep feedback anchored to the visible piece center, ignoring extra hit area.
            return Offset(width / 2, visualHeight / 2);
          }
        : childDragAnchorStrategy;

    return LongPressDraggable<PieceModel>(
      // Keep a minimal hold so taps don't trigger; effectively instant drag.
      delay: const Duration(milliseconds: 60),
      hapticFeedbackOnStart: true,
      data: piece,
      // Anchor drag to the widget center so lift/drag is purely vertical, regardless of tap position.
      dragAnchorStrategy: dragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: const Offset(0, -kPieceDragPointerYOffset),
          child: _buildContent(dragWidth, dragHeight, feedback: true, cellSizeOverride: dragCellSize),
        ),
      ),
      // Do not leave a ghost copy in the tray while dragging.
      childWhenDragging: placeholderWhileDragging,
      onDragStarted: () {
        onDragStart?.call();
        if (!isSelected) {
          onSelect(); // Select so board drops can succeed during drag.
        }
      },
      onDragUpdate: (details) => dragController?.updateHover(piece, details.globalPosition),
      // Only allow dragging for visual feedback; always snap back on release.
      onDragEnd: (details) {
        // Let the board decide; always clear hover so we don't leave floating previews.
        if (!details.wasAccepted) {
          // If no target accepted, let the board try to place based on the final pointer position.
          dragController?.completeDrop(piece, details.offset);
        }
        dragController?.cancelHover();
      },
      onDraggableCanceled: (_, __) => dragController?.cancelHover(),
      onDragCompleted: () => dragController?.cancelHover(),
      child: child,
    );
  }

  Widget _wrapWithHitArea(Widget content, double width, double height) {
    if (hitSlopTop <= 0) return content;
    return SizedBox(
      width: width,
      height: height + hitSlopTop,
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: Colors.transparent),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: content,
          ),
        ],
      ),
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
                child: BlockTile(size: tileSize, color: piece.color, pulse: !feedback && isSelected),
              ),
            )
            .toList(),
      ),
    );
  }
}
