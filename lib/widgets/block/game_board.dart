import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/piece_model.dart';
import '../../providers/block_puzzle_provider.dart';
import '../../providers/sound_provider.dart';
import 'block_tile.dart';
import 'particle_burst.dart';

class BlockGameBoard extends ConsumerStatefulWidget {
  const BlockGameBoard({
    super.key,
    required this.dimension,
  });

  final double dimension;

  @override
  ConsumerState<BlockGameBoard> createState() => _BlockGameBoardState();
}

class _BlockGameBoardState extends ConsumerState<BlockGameBoard> {
  static const double _padding = 18;
  static const double _gap = 6;
  final GlobalKey _boardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockPuzzleProvider);
    final board = SizedBox(
      key: _boardKey,
      width: widget.dimension,
      height: widget.dimension,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(details, state),
        child: DragTarget<PieceModel>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) => _handleDrop(details, state),
          builder: (context, candidateData, rejectedData) {
            return _buildGrid(context, state, candidateData.isNotEmpty);
          },
        ),
      ),
    );

    return SizedBox(
      width: widget.dimension,
      height: widget.dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: state.pulseBoard ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: board,
          ),
          ParticleBurst(visible: state.showParticleBurst, size: widget.dimension),
          Positioned(
            top: 24,
            child: AnimatedOpacity(
              opacity: state.showPerfectText ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Perfect!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black45, blurRadius: 12)],
                    ),
              ),
            ),
          ),
          if (state.status == BlockGameStatus.failed)
            Container(
              width: widget.dimension,
              height: widget.dimension,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(32),
              ),
              alignment: Alignment.center,
              child: Text(
                'No more moves',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, BlockPuzzleState state, bool highlightDrop) {
    final cellSize = _cellSize(state.size);
    return Container(
      width: widget.dimension,
      height: widget.dimension,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3B1E), Color(0xFF3B240F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
        ],
        border: Border.all(color: Colors.black54, width: 2),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black.withValues(alpha: 0.05),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          shrinkWrap: true,
          itemCount: state.size * state.size,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: state.size,
            crossAxisSpacing: _gap,
            mainAxisSpacing: _gap,
          ),
          itemBuilder: (context, index) {
            final row = index ~/ state.size;
            final col = index % state.size;
            final color = state.colorAt(row, col);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: highlightDrop ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
              ),
              child: BlockTile(
                size: cellSize,
                color: color,
                pulse: false,
              ),
            );
          },
        ),
      ),
    );
  }

  double _cellSize(int size) {
    final usable = widget.dimension - (_padding * 2) - (_gap * (size - 1));
    return max(usable / size, 12);
  }

  void _handleTap(TapUpDetails details, BlockPuzzleState state) {
    final position = details.localPosition;
    final cellSize = _cellSize(state.size);
    final row = ((position.dy - _padding) / (cellSize + _gap)).floor();
    final col = ((position.dx - _padding) / (cellSize + _gap)).floor();
    if (row.isNegative || col.isNegative || row >= state.size || col >= state.size) return;
    final success = ref.read(blockPuzzleProvider.notifier).tryPlaceSelected(row, col);
    if (success) {
      _handleFeedback();
    }
  }

  void _handleDrop(DragTargetDetails<PieceModel> details, BlockPuzzleState state) {
    final context = _boardKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final local = renderBox.globalToLocal(details.offset);
    final cellSize = _cellSize(state.size);
    final row = ((local.dy - _padding) / (cellSize + _gap)).floor();
    final col = ((local.dx - _padding) / (cellSize + _gap)).floor();
    if (row.isNegative || col.isNegative || row >= state.size || col >= state.size) return;
    final success = ref.read(blockPuzzleProvider.notifier).tryPlacePiece(details.data.id, row, col);
    if (success) {
      _handleFeedback();
    }
  }

  void _handleFeedback() {
    HapticFeedback.mediumImpact();
    final sounds = ref.read(soundControllerProvider);
    sounds.playBlockPlace();
    if (ref.read(blockPuzzleProvider).showParticleBurst) {
      sounds.playSuccess();
    }
  }
}
