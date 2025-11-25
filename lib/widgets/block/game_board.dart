import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';

import '../../models/piece_model.dart';
import '../../models/block_level_models.dart';
import '../../providers/block_puzzle_provider.dart';
import '../../providers/sound_provider.dart';
import 'block_tile.dart';
import 'particle_burst.dart';
import 'block_shatter_effect.dart';
import 'piece_drag_controller.dart';
import 'piece_drag_constants.dart';

class BlockGameBoard extends ConsumerStatefulWidget {
  const BlockGameBoard({
    super.key,
    required this.dimension,
    required this.provider,
    required this.dragController,
  });

  final double dimension;
  final StateNotifierProvider<BlockPuzzleNotifier, BlockPuzzleState> provider;
  final BlockDragController dragController;

  @override
  ConsumerState<BlockGameBoard> createState() => _BlockGameBoardState();
}

class _BlockGameBoardState extends ConsumerState<BlockGameBoard> {
  static const double _padding = 8;
  static const double _gap = 0.0;
  static const double _edgeTolerance = 220;
  static const _frameHighlight = Color(0xFFEBC68E);
  static const _frameMid = Color(0xFFC48337);
  static const _frameShadow = Color(0xFF8B4A1C);
  static const _frameEdge = Color(0xFF5C2C0F);
  static const _innerBoardDark = Color(0xFF2F170C);
  static const _innerBoardMid = Color(0xFF392314);
  static const _innerBoardEdge = Color(0xFF1F1209);
  static const _cellBase = Color(0xFF3B2112);
  static const _cellShadow = Color(0xFF140904);
  static const _cellHighlight = Color(0xFF5B3A22);
  final GlobalKey _boardKey = GlobalKey();
  int? _hoverRow;
  int? _hoverCol;
  PieceModel? _hoverPiece;
  bool _hoverValid = false;
  final Set<int> _seedVisible = <int>{};
  bool _seedAnimationScheduled = false;
  int? _seedSignature;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant BlockGameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragController != widget.dragController) {
      oldWidget.dragController.detach();
      _attachController();
    }
  }

  @override
  void dispose() {
    widget.dragController.detach();
    super.dispose();
  }

  void _attachController() {
    final controller = widget.dragController;
    controller.onHover = (piece, position) => _updateHoverFromGlobal(piece, position);
    controller.onDrop =
        (piece, position) => _handleDropAt(piece, position, ref.read(widget.provider));
    controller.onCancelHover = _clearHover;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    _maybeStartSeedIntro(state);
    final board = SizedBox(
      key: _boardKey,
      width: widget.dimension,
      height: widget.dimension,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(details, state),
        child: DragTarget<PieceModel>(
          onWillAcceptWithDetails: (details) {
            return _updateHoverPreview(details, state);
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
          ParticleBurst(
            visible: state.showParticleBurst,
            size: widget.dimension,
          ),
          Positioned(
            top: 24,
            child: AnimatedOpacity(
              opacity: state.showPerfectText ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                tr('block_game.perfect'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: state.showComboText ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                child: Center(
                  child: AnimatedScale(
                    scale: state.showComboText ? 1 : 0.92,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: Transform.rotate(
                      angle: -pi / 18,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tr(
                            'block_game.combo',
                            namedArgs: {'count': '${state.comboCount}'},
                          ),
                          style:
                              Theme.of(
                                context,
                              ).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: const Color(0xFFFFE9CC),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ) ??
                              const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: Color(0xFFFFE9CC),
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                        ),
                      ),
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
                padding: context.padding.low,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr('block_game.invalid_placement'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
                    state.levelMode
                        ? tr('block_game.level_failed')
                        : tr('block_game.no_moves'),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(widget.provider.notifier).restart(),
                    icon: const Icon(Iconsax.refresh, color: Colors.white,),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _maybeStartSeedIntro(BlockPuzzleState state) {
    final shouldAnimate =
        !state.seedIntroPlayed && state.seedIndices.isNotEmpty;
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
      final seedIndex = orderedSeeds[i];
      final isLastSeed = i == orderedSeeds.length - 1;
      Future.delayed(delay, () {
        if (!mounted) return;
        setState(() {
          _seedVisible.add(seedIndex);
        });
        if (isLastSeed) {
          Future.delayed(const Duration(milliseconds: 360), () {
            if (!mounted) return;
            ref.read(widget.provider.notifier).markSeedIntroPlayed();
          });
        }
      });
    }
  }

  Widget _buildGrid(BuildContext context, BlockPuzzleState state) {
    final padding = _boardPadding(context);
    final cellSize = _cellSize(state.size, padding);
    final previewCells = _previewCells(state);
    final baseRadius = _baseRadius(state.size);
    final pieceRadius = 0.0;
    final innerScale = state.size >= 10 ? 0.88 : 0.9;
    final blockSize = cellSize * innerScale;
    final explosionMap = <int, List<BlockExplosionEffect>>{};
    for (final effect in state.blockExplosions) {
      explosionMap
          .putIfAbsent(effect.index, () => <BlockExplosionEffect>[])
          .add(effect);
    }
    return Container(
      width: widget.dimension,
      height: widget.dimension,
      padding: EdgeInsets.all(padding),
      decoration: _outerFrameDecoration(),
      child: DecoratedBox(
        decoration: _innerBoardDecoration(),
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
            final seedVisible =
                state.seedIntroPlayed || _seedVisible.contains(index);
            final shatters = explosionMap[index];
            Widget tile = Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: _cellDecoration(baseRadius),
                ),
                if (color != null)
                  BlockTile(
                    size: blockSize,
                    color: color,
                    pulse: false,
                    borderRadius: pieceRadius,
                    bounceOnAppear: isSeedCell && seedVisible,
                  ),
                if (shatters != null)
                  ...shatters.map(
                    (effect) => BlockShatterEffect(
                      key: ValueKey(effect.id),
                      size: blockSize,
                      color: effect.color,
                      seed: effect.id,
                    ),
                  ),
                if (state.levelMode)
                  _LevelTokenOverlay(
                    token: state.levelTokenAt(row, col),
                    cellSize: cellSize,
                  ),
                if (isPreviewCell)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(baseRadius),
                      color: _previewColor(),
                      border: Border.all(
                        color: _hoverValid
                            ? Colors.green.shade800
                            : Colors.redAccent,
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

  double _cellSize(int size, double padding) {
    final usable = widget.dimension - (padding * 2) - (_gap * (size - 1));
    return max(usable / size, 18);
  }

  void _handleTap(TapUpDetails details, BlockPuzzleState state) {
    final coords = _coordsFromLocal(
      details.localPosition,
      state,
      strictBounds: true,
    );
    if (coords == null) return;
    final success = ref
        .read(widget.provider.notifier)
        .tryPlaceSelected(coords.row, coords.col);
    if (success) {
      _handleFeedback();
    }
  }

  void _handleDrop(
    DragTargetDetails<PieceModel> details,
    BlockPuzzleState state,
  ) {
    _handleDropAt(details.data, details.offset, state);
  }

  void _handleDropAt(
    PieceModel piece,
    Offset globalPosition,
    BlockPuzzleState state,
  ) {
    final coords = _coordsFromGlobal(globalPosition, state);
    if (coords == null) {
      _clearHover();
      return;
    }
    final success = ref
        .read(widget.provider.notifier)
        .tryPlacePiece(piece.id, coords.row, coords.col);
    _clearHover();
    if (success) {
      _handleFeedback();
    }
  }

  bool _updateHoverPreview(
    DragTargetDetails<PieceModel> details,
    BlockPuzzleState state,
  ) {
    return _setHoverState(details.data, details.offset, state);
  }

  void _updateHoverFromGlobal(
    PieceModel piece,
    Offset globalPosition,
  ) {
    final state = ref.read(widget.provider);
    _setHoverState(piece, globalPosition, state);
  }

  bool _setHoverState(
    PieceModel piece,
    Offset globalPosition,
    BlockPuzzleState state,
  ) {
    final coords = _coordsFromGlobal(globalPosition, state);
    if (coords == null) {
      _clearHover();
      return false;
    }
    final fits = _canPreviewPlace(piece, coords.row, coords.col, state);
    setState(() {
      _hoverRow = coords.row;
      _hoverCol = coords.col;
      _hoverPiece = piece;
      _hoverValid = fits;
    });
    return fits;
  }

  void _clearHover() {
    if (_hoverPiece == null &&
        _hoverRow == null &&
        _hoverCol == null &&
        !_hoverValid)
      return;
    setState(() {
      _hoverRow = null;
      _hoverCol = null;
      _hoverPiece = null;
      _hoverValid = false;
    });
  }

  bool _canPreviewPlace(
    PieceModel piece,
    int row,
    int col,
    BlockPuzzleState state,
  ) {
    for (final block in piece.blocks) {
      final targetRow = row + block.rowOffset;
      final targetCol = col + block.colOffset;
      if (targetRow < 0 ||
          targetCol < 0 ||
          targetRow >= state.size ||
          targetCol >= state.size) {
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
    if (_hoverPiece == null || _hoverRow == null || _hoverCol == null)
      return <int>{};
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
    final base = _hoverValid
        ? _hoverPiece?.color ?? Colors.white
        : Colors.redAccent;
    return base.withValues(alpha: _hoverValid ? 0.45 : 0.35);
  }

  ({int row, int col})? _coordsFromGlobal(
    Offset globalPosition,
    BlockPuzzleState state,
  ) {
    final context = _boardKey.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final adjustedOffset =
        globalPosition.translate(0, -kPieceDragPointerYOffset);
    final local = renderBox.globalToLocal(adjustedOffset);
    return _coordsFromLocal(local, state);
  }

  ({int row, int col})? _coordsFromLocal(
    Offset local,
    BlockPuzzleState state, {
    bool strictBounds = false,
  }) {
    final padding = _resolvedPadding();
    final boardStart = padding;
    final boardEnd = widget.dimension - padding;
    final dynamicTolerance = max(_edgeTolerance, _cellSize(state.size, padding));
    final tolerance = strictBounds ? 0 : dynamicTolerance;
    final withinHorizontal =
        local.dx >= boardStart - tolerance && local.dx <= boardEnd + tolerance;
    final withinVertical =
        local.dy >= boardStart - tolerance && local.dy <= boardEnd + tolerance;
    if (!withinHorizontal || !withinVertical) {
      return null;
    }
    final clampedX = local.dx.clamp(boardStart, boardEnd - 0.0001);
    final clampedY = local.dy.clamp(boardStart, boardEnd - 0.0001);
    final cellSize = _cellSize(state.size, padding);
    final extent = cellSize + _gap;
    final relativeX = clampedX - boardStart;
    final relativeY = clampedY - boardStart;
    final maxIndex = state.size - 1e-3;
    final columnPosition = (relativeX / extent).clamp(0, maxIndex);
    final rowPosition = (relativeY / extent).clamp(0, maxIndex);
    final col = columnPosition.floor();
    final row = rowPosition.floor();
    return (row: row, col: col);
  }

  void _handleFeedback() {
    HapticFeedback.mediumImpact();
    final sounds = ref.read(soundControllerProvider);
    sounds.playBlockPlace();
    if (ref.read(widget.provider).showParticleBurst) {
      sounds.playSuccess();
    }
  }

  double _boardPadding(BuildContext context) =>
      max(_padding, context.dynamicHeight(0.005));

  double _resolvedPadding() {
    final context = _boardKey.currentContext;
    if (context != null) return _boardPadding(context);
    return _padding;
  }

  BoxDecoration _outerFrameDecoration() {
    return BoxDecoration(
      borderRadius: context.border.lowBorderRadius,
      gradient: const LinearGradient(
        colors: [_frameHighlight, _frameMid, _frameShadow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: _frameEdge, width: 2.4),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 6,
          offset: Offset(0, -2),
        ),
      ],
    );
  }

  BoxDecoration _innerBoardDecoration() {
    return BoxDecoration(
      borderRadius: context.border.lowBorderRadius,
      gradient: const LinearGradient(
        colors: [_innerBoardMid, _innerBoardDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: Border.all(color: _innerBoardEdge, width: 1.4),
    );
  }

  BoxDecoration _cellDecoration(double radius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius + 6),
      gradient: const LinearGradient(
        colors: [_cellHighlight, _cellBase],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: Colors.black.withValues(alpha: 0.35),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          offset: Offset(0, 1.6),
          blurRadius: 2.2,
        ),
        BoxShadow(
          color: Color(0x22000000),
          offset: Offset(0, -1.2),
          blurRadius: 1.6,
        ),
      ],
    );
  }
}

double _baseRadius(int size) => 0;

class _LevelTokenOverlay extends StatelessWidget {
  const _LevelTokenOverlay({required this.token, required this.cellSize});

  final BlockLevelToken? token;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    if (token == null) return const SizedBox.shrink();
    return Image.asset(
      token!.asset,
      width: cellSize * 0.6,
      height: cellSize * 0.6,
      fit: BoxFit.contain,
    );
  }
}
