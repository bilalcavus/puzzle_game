import 'package:flutter/material.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';

import '../../models/piece_model.dart';
import 'block_tile.dart';

class PieceWidget extends StatelessWidget {
  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.onSelect,
    this.onDragStart,
    this.isSelected = false,
    this.disabled = false,
  });

  final PieceModel piece;
  final double cellSize;
  final VoidCallback onSelect;
  final VoidCallback? onDragStart;
  final bool isSelected;
  final bool disabled;
  static const double _dragFeedbackScale = 1.4;

  @override
  Widget build(BuildContext context) {
    final footprintWidth = (piece.width * cellSize) + 8;
    final footprintHeight = (piece.height * cellSize) + 8;
    final dragCellSize = cellSize * _dragFeedbackScale;
    final dragWidth = (piece.width * dragCellSize) + 8;
    final dragHeight = (piece.height * dragCellSize) + 8;
    final content = _buildContent(footprintWidth, footprintHeight);
    final child = Opacity(
      opacity: disabled ? 0.4 : 1,
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
    );

    if (disabled) {
      return child;
    }

    return GestureDetector(
      onTap: onSelect,
      child: Draggable<PieceModel>(
        data: piece,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: _buildContent(
            dragWidth,
            dragHeight,
            feedback: true,
            cellSizeOverride: dragCellSize,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: child),
        onDragStarted: () {
          onDragStart?.call();
          onSelect();
        },
        child: child,
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
