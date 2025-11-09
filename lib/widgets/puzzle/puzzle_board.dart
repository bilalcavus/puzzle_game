import 'package:flutter/material.dart';

import '../../models/puzzle_model.dart';
import 'puzzle_tile.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({super.key, required this.puzzle, required this.dimension});

  final PuzzleModel puzzle;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final tileSize = dimension / puzzle.size;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40)),
      ),
      child: Stack(
        children: [
          ...puzzle.tiles
              .where((tile) => !tile.isEmpty)
              .map((tile) => PuzzleTile(tile: tile, tileSize: tileSize)),
        ],
      ),
    );
  }
}
