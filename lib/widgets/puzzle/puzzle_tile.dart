import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tile_model.dart';
import '../../providers/puzzle_provider.dart';
import '../../providers/sound_provider.dart';
import '../components/tile_widget.dart';

class PuzzleTile extends ConsumerWidget {
  const PuzzleTile({super.key, required this.tile, required this.tileSize});

  final TileModel tile;
  final double tileSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      left: tile.currentCol * tileSize,
      top: tile.currentRow * tileSize,
      child: LongPressDraggable<int>(
        data: tile.value,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: TileWidget(text: '${tile.value}', size: tileSize, highlight: true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: _buildTile(context),
        ),
        onDragEnd: (_) => _handleMove(ref),
        child: GestureDetector(
          onTap: () => _handleMove(ref),
          child: _buildTile(context),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    return TileWidget(
      text: tile.value.toString(),
      size: tileSize,
      highlight: tile.isInCorrectPosition,
    );
  }

  void _handleMove(WidgetRef ref) {
    final moved = ref.read(puzzleProvider.notifier).tryMove(tile.value);
    if (moved) {
      HapticFeedback.selectionClick();
      ref.read(soundControllerProvider).playMove();
    }
  }
}
