import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/app/ads_service.dart';
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
  // Reduce padding so cells gain more usable area.
  static const double _padding = 4;
  static const double _gap = 0.0;
  static const double _dropSnapMargin = 150;
  static const _frameHighlight = Color(0xFFEBC68E);
  static const _frameMid = Color(0xFFC48337);
  static const _frameShadow = Color(0xFF8B4A1C);
  static const _frameEdge = Color(0xFF5C2C0F);
  static const _innerBoardDark = Color(0xFF2F170C);
  static const _innerBoardMid = Color(0xFF392314);
  static const _innerBoardEdge = Color(0xFF1F1209);
  static const _cellBase = Color(0xFF3B2112);
  static const _cellHighlight = Color(0xFF5B3A22);
  final GlobalKey _boardKey = GlobalKey();
  int? _hoverRow;
  int? _hoverCol;
  PieceModel? _hoverPiece;
  bool _hoverValid = false;
  // Persist last valid hover so drop uses the position user saw.
  int? _lastHoverRow;
  int? _lastHoverCol;
  String? _lastHoverPieceId;
  Set<int> _hoverClearRows = <int>{};
  Set<int> _hoverClearCols = <int>{};
  final Set<int> _seedVisible = <int>{};
  bool _seedAnimationScheduled = false;
  int? _seedSignature;
  final adsService = AdsService();
  bool _gameOverAdShown = false;
  int _levelFailCounter = 0;
  int _classicFailCounter = 0;
  int _nextClassicScoreMilestone = 10000;

  @override
  void initState() {
    super.initState();
    _attachController();
    _nextClassicScoreMilestone = _computeNextClassicScoreMilestone(
      ref.read(widget.provider),
    );
    adsService.loadInterstitial(); // ✅ oyun başında hazırlar

    // ✅ GAME OVER OTOMATİK INTERSTITIAL DİNLEYİCİ
    ref.listenManual<BlockPuzzleState>(widget.provider, (previous, next) {
      _handleModeSwitch(previous, next);
      _handleGameOverAd(previous, next);
      _handleClassicScoreMilestones(previous, next);
    });
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

  void _handleModeSwitch(BlockPuzzleState? previous, BlockPuzzleState next) {
    final previousMode = previous?.levelMode;
    if (previousMode == null || previousMode == next.levelMode) return;
    _gameOverAdShown = false;
    if (next.levelMode) {
      _classicFailCounter = 0;
    } else {
      _levelFailCounter = 0;
      _nextClassicScoreMilestone = _computeNextClassicScoreMilestone(next);
    }
  }

  void _handleGameOverAd(BlockPuzzleState? previous, BlockPuzzleState next) {
    final hasFailed =
        previous?.status != BlockGameStatus.failed &&
        next.status == BlockGameStatus.failed;
    if (hasFailed) {
      if (next.levelMode) {
        _levelFailCounter++;
        final shouldShow = next.level > 10 ? true : _levelFailCounter % 3 == 0;
        if (shouldShow) {
          _showInterstitial(markGameOver: true);
        }
      } else {
        _classicFailCounter++;
        if (_classicFailCounter % 2 == 0) {
          _showInterstitial(markGameOver: true);
        }
      }
      return;
    }
    if (previous?.status == BlockGameStatus.failed &&
        next.status == BlockGameStatus.playing) {
      _gameOverAdShown = false;
    }
  }

  void _handleClassicScoreMilestones(
    BlockPuzzleState? previous,
    BlockPuzzleState next,
  ) {
    if (next.levelMode || next.status != BlockGameStatus.playing) return;
    final prevScore = previous?.score ?? next.score;
    if (next.score >= _nextClassicScoreMilestone &&
        prevScore < _nextClassicScoreMilestone) {
      _showInterstitial();
    }
    while (_nextClassicScoreMilestone <= next.score) {
      _nextClassicScoreMilestone += 10000;
    }
  }

  int _computeNextClassicScoreMilestone(BlockPuzzleState state) {
    final next = ((state.score ~/ 10000) + 1) * 10000;
    return max(10000, next);
  }

  void _showInterstitial({bool markGameOver = false}) {
    if (markGameOver && _gameOverAdShown) return;
    if (markGameOver) {
      _gameOverAdShown = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adsService.showInterstitial();
    });
  }

  Widget _buildComboOverlay(BlockPuzzleState state, BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          color: const Color(0xFFFFE9CC),
          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 6),
          ],
        ) ??
        const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          color: Color(0xFFFFE9CC),
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 6),
          ],
        );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final scale = Tween<double>(begin: 0.9, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: state.showComboText
          ? RepaintBoundary(
              key: const ValueKey('combo-visible'),
              child: Center(
                child: Transform.rotate(
                  angle: -pi / 18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr(
                        'block_game.combo',
                        namedArgs: {'count': '${state.comboCount}'},
                      ),
                      style: textStyle,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(key: ValueKey('combo-hidden')),
    );
  }

  void _attachController() {
    final controller = widget.dragController;
    controller.onHover = (piece, position) =>
        _updateHoverFromGlobal(piece, position);
    controller.onDrop = (piece, position) =>
        _handleDropAt(piece, position, ref.read(widget.provider));
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
      child: DragTarget<PieceModel>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          _clearHover();
          _handleDrop(details, state);
        },
        builder: (context, candidateData, rejectedData) {
          return _buildGrid(context, state);
        },
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
            child: IgnorePointer(child: _buildComboOverlay(state, context)),
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
                    onPressed: () {
                      _gameOverAdShown = false;
                      ref.read(widget.provider.notifier).restart();
                    },
                    icon: const Icon(Iconsax.refresh, color: Colors.white),
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
    final rowGlow = <int, Color>{};
    final colGlow = <int, Color>{};
    final rowGlowGradients = <int, List<Color>>{};
    final colGlowGradients = <int, List<Color>>{};
    for (final effect in state.lineEffects) {
      final colors = _lineGradient(effect.color);
      if (effect.isRow) {
        rowGlow[effect.index] = colors.first;
        rowGlowGradients[effect.index] = colors;
      } else {
        colGlow[effect.index] = colors.first;
        colGlowGradients[effect.index] = colors;
      }
    }
    if (_hoverValid && _hoverPiece != null) {
      final previewGradient = _hoverLineGradient();
      final previewColor = previewGradient[previewGradient.length ~/ 2];
      for (final row in _hoverClearRows) {
        rowGlow[row] = previewColor;
        rowGlowGradients[row] = previewGradient;
      }
      for (final col in _hoverClearCols) {
        colGlow[col] = previewColor;
        colGlowGradients[col] = previewGradient;
      }
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
            final gradientColors =
                rowGlowGradients[row] ?? colGlowGradients[col];
            final glowColor = gradientColors != null
                ? gradientColors[gradientColors.length ~/ 2]
                : (rowGlow[row] ?? colGlow[col]);
            Widget tile = Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: _cellDecoration(baseRadius),
                ),
                if (glowColor != null)
                  AnimatedOpacity(
                    opacity: 0.95,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(baseRadius),
                        gradient: LinearGradient(
                          colors:
                              gradientColors ??
                              [
                                glowColor.withValues(alpha: 0.12),
                                glowColor.withValues(alpha: 0.45),
                                glowColor.withValues(alpha: 0.14),
                              ],
                          begin: rowGlow.containsKey(row)
                              ? Alignment.centerLeft
                              : Alignment.topCenter,
                          end: rowGlow.containsKey(row)
                              ? Alignment.centerRight
                              : Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _SparkleOverlay(color: glowColor, seed: index),
                    ),
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
                if (state.levelMode && !state.levelCompleted)
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
                            ? Colors.green.shade600
                            : Colors.transparent,
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
    final dropWithinBoardZone = _isWithinDropZone(globalPosition);
    if (!dropWithinBoardZone) {
      _clearHover();
      ref.read(widget.provider.notifier).selectPiece(piece.id);
      return;
    }

    // Only honor the last hover location if the pointer is still within the board's snap area.
    final canReuseHover =
        _lastHoverPieceId == piece.id &&
        _lastHoverRow != null &&
        _lastHoverCol != null;
    final coords = canReuseHover
        ? (row: _lastHoverRow!, col: _lastHoverCol!)
        : _coordsFromGlobal(piece, globalPosition, state);
    if (coords == null) {
      _clearHover();
      // Deselect the piece so it returns to the tray when dropped off-board.
      ref.read(widget.provider.notifier).selectPiece(piece.id);
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

  void _updateHoverFromGlobal(PieceModel piece, Offset globalPosition) {
    final state = ref.read(widget.provider);
    _setHoverState(piece, globalPosition, state);
  }

  bool _setHoverState(
    PieceModel piece,
    Offset globalPosition,
    BlockPuzzleState state,
  ) {
    final coords = _coordsFromGlobal(piece, globalPosition, state);
    if (coords == null) {
      _clearHover();
      return false;
    }
    final fits = _canPreviewPlace(piece, coords.row, coords.col, state);
    final hoverClears = fits
        ? _predictClears(piece, coords.row, coords.col, state)
        : (rows: <int>[], cols: <int>[]);
    setState(() {
      _hoverRow = coords.row;
      _hoverCol = coords.col;
      _hoverPiece = piece;
      _hoverValid = fits;
      _hoverClearRows = hoverClears.rows.toSet();
      _hoverClearCols = hoverClears.cols.toSet();
      if (fits) {
        _lastHoverRow = coords.row;
        _lastHoverCol = coords.col;
        _lastHoverPieceId = piece.id;
      }
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
      _hoverClearRows = <int>{};
      _hoverClearCols = <int>{};
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

  ({List<int> rows, List<int> cols}) _predictClears(
    PieceModel piece,
    int row,
    int col,
    BlockPuzzleState state,
  ) {
    final size = state.size;
    final filled = Map<int, Color>.from(state.filledCells);
    for (final block in piece.blocks) {
      final targetRow = row + block.rowOffset;
      final targetCol = col + block.colOffset;
      if (targetRow < 0 ||
          targetCol < 0 ||
          targetRow >= size ||
          targetCol >= size) {
        continue;
      }
      filled[targetRow * size + targetCol] = piece.color;
    }

    final clearedRows = <int>[];
    final clearedCols = <int>[];
    for (var r = 0; r < size; r++) {
      var full = true;
      for (var c = 0; c < size; c++) {
        if (!filled.containsKey(r * size + c)) {
          full = false;
          break;
        }
      }
      if (full) clearedRows.add(r);
    }
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (!filled.containsKey(r * size + c)) {
          full = false;
          break;
        }
      }
      if (full) clearedCols.add(c);
    }
    return (rows: clearedRows, cols: clearedCols);
  }

  Set<int> _previewCells(BlockPuzzleState state) {
    if (!_hoverValid ||
        _hoverPiece == null ||
        _hoverRow == null ||
        _hoverCol == null) {
      return <int>{};
    }
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
    final base = _hoverPiece?.color ?? Colors.white;
    return base.withValues(alpha: 0.28);
  }

  List<Color> _hoverLineGradient() {
    return const [
      Color(0xFFFFC94A), // yellow
      Color.fromARGB(255, 255, 210, 76), // cyan
    ];
  }

  List<Color> _lineGradient(Color base) {
    final hsl = HSLColor.fromColor(base);
    final brighter = hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0));
    final shifted = hsl
        .withHue((hsl.hue + 24) % 360)
        .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0));
    final deep = hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0));
    return [brighter.toColor(), shifted.toColor(), deep.toColor()];
  }

  Rect? _boardRect() {
    final context = _boardKey.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final boardOrigin = renderBox.localToGlobal(Offset.zero);
    return boardOrigin & renderBox.size;
  }

  bool _isWithinDropZone(Offset globalPosition) {
    final rect = _boardRect();
    if (rect == null) return false;
    return rect.inflate(_dropSnapMargin).contains(globalPosition);
  }

  ({int row, int col})? _coordsFromGlobal(
    PieceModel piece,
    Offset globalPosition,
    BlockPuzzleState state,
  ) {
    final boardRect = _boardRect();
    if (boardRect == null) return null;
    if (!boardRect.inflate(_dropSnapMargin).contains(globalPosition)) {
      return null;
    }

    final boardOrigin = boardRect.topLeft;
    // Pointer + fixed lift to match drag feedback (piece shown 100px above finger).
    final adjustedOffset = globalPosition.translate(
      0,
      -kPieceDragPointerYOffset,
    );

    final padding = _resolvedPadding();
    final cellSize = _cellSize(state.size, padding);
    final extent = cellSize + _gap;
    // Piece rect in global coordinates, centered on the adjusted pointer (no clamp; use overlap scoring).
    final pieceWidthPx = piece.width * extent - _gap;
    final pieceHeightPx = piece.height * extent - _gap;
    final pieceLeft = adjustedOffset.dx - (pieceWidthPx / 2);
    final pieceTop = adjustedOffset.dy - (pieceHeightPx / 2);
    final pieceRect = Rect.fromLTWH(
      pieceLeft,
      pieceTop,
      pieceWidthPx,
      pieceHeightPx,
    );
    final pieceArea = pieceRect.width * pieceRect.height;

    double bestRatio = -1;
    int? bestRow;
    int? bestCol;

    // Evaluate every clear placement; choose the one with maximum overlap ratio.
    for (var r = 0; r <= state.size - piece.height; r++) {
      final cellTopGlobal = boardOrigin.dy + padding + r * extent;
      for (var c = 0; c <= state.size - piece.width; c++) {
        if (!_isPlacementClear(piece, r, c, state)) continue;
        final cellLeftGlobal = boardOrigin.dx + padding + c * extent;
        final placementRect = Rect.fromLTWH(
          cellLeftGlobal,
          cellTopGlobal,
          pieceWidthPx,
          pieceHeightPx,
        );
        final overlap = _rectIntersectionArea(pieceRect, placementRect);
        if (overlap <= 0) continue;
        final ratio = overlap / pieceArea;
        if (ratio > bestRatio) {
          bestRatio = ratio;
          bestRow = r;
          bestCol = c;
        }
      }
    }

    // Minimal overlap guard to avoid snapping when not really on board.
    if (bestRow == null || bestCol == null) return null;
    if (bestRatio < 0.05) return null;
    return (row: bestRow, col: bestCol);
  }

  bool _isPlacementClear(
    PieceModel piece,
    int baseRow,
    int baseCol,
    BlockPuzzleState state,
  ) {
    for (final block in piece.blocks) {
      final r = baseRow + block.rowOffset;
      final c = baseCol + block.colOffset;
      if (r < 0 || c < 0 || r >= state.size || c >= state.size) {
        return false;
      }
      final idx = r * state.size + c;
      if (state.filledCells.containsKey(idx)) {
        return false;
      }
    }
    return true;
  }

  double _rectIntersectionArea(Rect a, Rect b) {
    final double xOverlap = max(0, min(a.right, b.right) - max(a.left, b.left));
    final double yOverlap = max(0, min(a.bottom, b.bottom) - max(a.top, b.top));
    return xOverlap * yOverlap;
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
      border: Border.all(color: _frameEdge, width: 1.4),
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
      border: Border.all(color: _innerBoardEdge, width: 0.9),
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
      border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: 1),
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
      width: cellSize * 0.78,
      height: cellSize * 0.78,
      fit: BoxFit.contain,
    );
  }
}

class _SparkleOverlay extends StatelessWidget {
  const _SparkleOverlay({required this.color, required this.seed});

  final Color color;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final random = Random(seed);
    final dots = List.generate(6, (index) {
      final size = 3 + random.nextDouble() * 3.5;
      final dx = (random.nextDouble() * 1.6) - 0.8;
      final dy = (random.nextDouble() * 1.6) - 0.8;
      return Align(
        alignment: Alignment(dx, dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 8,
                spreadRadius: 0.8,
              ),
            ],
          ),
        ),
      );
    });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Stack(children: dots),
    );
  }
}
