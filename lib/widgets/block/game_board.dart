import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';

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
  static const double _padding = 10;
  static const double _gap = 4;
  final GlobalKey _boardKey = GlobalKey();
  int? _hoverRow;
  int? _hoverCol;
  PieceModel? _hoverPiece;
  bool _hoverValid = false;
  final Set<int> _seedVisible = <int>{};
  bool _seedAnimationScheduled = false;
  int? _seedSignature;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockPuzzleProvider);
    _maybeStartSeedIntro(state);
    final board = SizedBox(
      key: _boardKey,
      width: widget.dimension,
      height: widget.dimension,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(details, state),
        child: DragTarget<PieceModel>(
          onWillAcceptWithDetails: (details) {
            _updateHoverPreview(details, state);
            return true;
          },
          onMove: (details) => _updateHoverPreview(details, state),
          onLeave: (_) => _clearHover(),
          onAcceptWithDetails: (details) {
            _clearHover();
            _handleDrop(details, state);
          },
          builder: (context, candidateData, rejectedData) {
            return _buildGrid(context, state);
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
          Positioned(
            top: 80,
            child: AnimatedOpacity(
              opacity: state.showComboText ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: AnimatedScale(
                scale: state.showComboText ? 1 : 0.9,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Text(
                    'Combo x${state.comboCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: state.showInvalidPlacement ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Blok bu alana sığmıyor',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No more moves',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  IconButton(onPressed: () => ref.read(blockPuzzleProvider.notifier).restart(), icon: Icon(Iconsax.refresh)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _maybeStartSeedIntro(BlockPuzzleState state) {
    final shouldAnimate = !state.seedIntroPlayed && state.seedIndices.isNotEmpty;
    if (!shouldAnimate) {
      if (_seedVisible.isNotEmpty) {
        setState(() {
          _seedVisible.clear();
        });
      }
      _seedAnimationScheduled = false;
      _seedSignature = null;
      return;
    }
    final orderedSeeds = state.seedIndices.toList()
      ..sort((a, b) {
        final size = state.size;
        final ar = a ~/ size;
        final ac = a % size;
        final br = b ~/ size;
        final bc = b % size;
        final aScore = ar + ac;
        final bScore = br + bc;
        final scoreCompare = aScore.compareTo(bScore);
        if (scoreCompare != 0) return scoreCompare;
        final diagCompare = (ar - ac).abs().compareTo((br - bc).abs());
        if (diagCompare != 0) return diagCompare;
        return ar.compareTo(br);
      });
    final signature = Object.hashAll(orderedSeeds);
    if (_seedAnimationScheduled && _seedSignature == signature) {
      return;
    }
    _seedAnimationScheduled = true;
    _seedSignature = signature;
    _seedVisible.clear();
    for (var i = 0; i < orderedSeeds.length; i++) {
      final delay = Duration(milliseconds: 28 * i);
      Future.delayed(delay, () {
        if (!mounted) return;
        setState(() {
          _seedVisible.add(orderedSeeds[i]);
        });
        if (i == orderedSeeds.length - 1) {
          Future.delayed(const Duration(milliseconds: 360), () {
            if (!mounted) return;
            ref.read(blockPuzzleProvider.notifier).markSeedIntroPlayed();
          });
        }
      });
    }
  }

  Widget _buildGrid(BuildContext context, BlockPuzzleState state) {
    final cellSize = _cellSize(state.size);
    final previewCells = _previewCells(state);
    final tileRadius = state.size >= 10 ? 8.0 : 14.0;
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
            final isPreviewCell = previewCells.contains(index);
            final isSeedCell = state.seedIndices.contains(index);
            final seedVisible = state.seedIntroPlayed || _seedVisible.contains(index);
            Widget tile = Stack(
              alignment: Alignment.center,
              children: [
                BlockTile(
                  size: cellSize,
                  color: color,
                  pulse: false,
                  borderRadius: tileRadius,
                ),
                if (isPreviewCell)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.dynamicHeight(0.02)),
                      color: _previewColor(),
                      border: Border.all(
                        color: _hoverValid ? Colors.green.shade800 : Colors.redAccent,
                        width: 1.0,
                      ),
                    ),
                  ),
              ],
            );
            if (isSeedCell && !state.seedIntroPlayed) {
              tile = AnimatedOpacity(
                opacity: seedVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: seedVisible ? 1 : 0.7,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: tile,
                ),
              );
            }
            return tile;
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

  void _updateHoverPreview(DragTargetDetails<PieceModel> details, BlockPuzzleState state) {
    final context = _boardKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final local = renderBox.globalToLocal(details.offset);
    final cellSize = _cellSize(state.size);
    final row = ((local.dy - _padding) / (cellSize + _gap)).floor();
    final col = ((local.dx - _padding) / (cellSize + _gap)).floor();
    if (row.isNegative || col.isNegative || row >= state.size || col >= state.size) {
      _clearHover();
      return;
    }
    final fits = _canPreviewPlace(details.data, row, col, state);
    setState(() {
      _hoverRow = row;
      _hoverCol = col;
      _hoverPiece = details.data;
      _hoverValid = fits;
    });
  }

  void _clearHover() {
    if (_hoverPiece == null && _hoverRow == null && _hoverCol == null && !_hoverValid) return;
    setState(() {
      _hoverRow = null;
      _hoverCol = null;
      _hoverPiece = null;
      _hoverValid = false;
    });
  }

  bool _canPreviewPlace(PieceModel piece, int row, int col, BlockPuzzleState state) {
    for (final block in piece.blocks) {
      final targetRow = row + block.rowOffset;
      final targetCol = col + block.colOffset;
      if (targetRow < 0 || targetCol < 0 || targetRow >= state.size || targetCol >= state.size) {
        return false;
      }
      final index = targetRow * state.size + targetCol;
      if (state.filledCells.containsKey(index)) {
        return false;
      }
    }
    return true;
  }

  Set<int> _previewCells(BlockPuzzleState state) {
    if (_hoverPiece == null || _hoverRow == null || _hoverCol == null) return <int>{};
    final size = state.size;
    final indices = <int>{};
    for (final block in _hoverPiece!.blocks) {
      final row = _hoverRow! + block.rowOffset;
      final col = _hoverCol! + block.colOffset;
      if (row < 0 || col < 0 || row >= size || col >= size) continue;
      indices.add(row * size + col);
    }
    return indices;
  }

  Color _previewColor() {
    final base = _hoverValid ? _hoverPiece?.color ?? Colors.white : Colors.redAccent;
    return base.withValues(alpha: _hoverValid ? 0.45 : 0.35);
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
