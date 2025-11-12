import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/block_leaderboard_entry.dart';
import '../models/block_level_models.dart';
import '../models/piece_model.dart';
import 'block_leaderboard_provider.dart';
import '../core/utils/block_piece_factory.dart';
import 'sound_provider.dart';

final blockPuzzleProvider = StateNotifierProvider<BlockPuzzleNotifier, BlockPuzzleState>(
  (ref) => BlockPuzzleNotifier(ref),
);

enum BlockGameStatus { playing, failed }

const _selectionSentinel = Object();

class BlockPuzzleState {
  const BlockPuzzleState({
    required this.size,
    required this.filledCells,
    required this.seedIndices,
    required this.availablePieces,
    required this.selectedPieceId,
    required this.score,
    required this.bestScore,
    required this.totalLinesCleared,
    required this.status,
    required this.showPerfectText,
    required this.showParticleBurst,
    required this.pulseBoard,
    required this.showInvalidPlacement,
    required this.seedIntroPlayed,
    required this.comboCount,
    required this.showComboText,
    required this.levelMode,
    required this.level,
    required this.levelGoals,
    required this.levelTargets,
    required this.levelCompleted,
  });

  final int size;
  final Map<int, Color> filledCells;
  final Set<int> seedIndices;
  final List<PieceModel> availablePieces;
  final String? selectedPieceId;
  final int score;
  final int bestScore;
  final int totalLinesCleared;
  final BlockGameStatus status;
  final bool showPerfectText;
  final bool showParticleBurst;
  final bool pulseBoard;
  final bool showInvalidPlacement;
  final bool seedIntroPlayed;
  final int comboCount;
  final bool showComboText;
  final bool levelMode;
  final int level;
  final List<BlockLevelGoal> levelGoals;
  final Map<int, BlockLevelToken> levelTargets;
  final bool levelCompleted;

  PieceModel? get selectedPiece {
    if (selectedPieceId == null) return null;
    for (final piece in availablePieces) {
      if (piece.id == selectedPieceId) return piece;
    }
    return null;
  }

  Color? colorAt(int row, int col) => filledCells[row * size + col];

  BlockLevelToken? levelTokenAt(int row, int col) => levelTargets[row * size + col];

  BlockPuzzleState copyWith({
    int? size,
    Map<int, Color>? filledCells,
    Set<int>? seedIndices,
    List<PieceModel>? availablePieces,
    Object? selectedPieceId = _selectionSentinel,
    int? score,
    int? bestScore,
    int? totalLinesCleared,
    BlockGameStatus? status,
    bool? showPerfectText,
    bool? showParticleBurst,
    bool? pulseBoard,
    bool? showInvalidPlacement,
    bool? seedIntroPlayed,
    int? comboCount,
    bool? showComboText,
    bool? levelMode,
    int? level,
    List<BlockLevelGoal>? levelGoals,
    Map<int, BlockLevelToken>? levelTargets,
    bool? levelCompleted,
  }) {
    return BlockPuzzleState(
      size: size ?? this.size,
      filledCells: filledCells ?? this.filledCells,
      seedIndices: seedIndices ?? this.seedIndices,
      availablePieces: availablePieces ?? this.availablePieces,
      selectedPieceId: identical(selectedPieceId, _selectionSentinel) ? this.selectedPieceId : selectedPieceId as String?,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      totalLinesCleared: totalLinesCleared ?? this.totalLinesCleared,
      status: status ?? this.status,
      showPerfectText: showPerfectText ?? this.showPerfectText,
      showParticleBurst: showParticleBurst ?? this.showParticleBurst,
      pulseBoard: pulseBoard ?? this.pulseBoard,
      showInvalidPlacement: showInvalidPlacement ?? this.showInvalidPlacement,
      seedIntroPlayed: seedIntroPlayed ?? this.seedIntroPlayed,
      comboCount: comboCount ?? this.comboCount,
      showComboText: showComboText ?? this.showComboText,
      levelMode: levelMode ?? this.levelMode,
      level: level ?? this.level,
      levelGoals: levelGoals ?? this.levelGoals,
      levelTargets: levelTargets ?? this.levelTargets,
      levelCompleted: levelCompleted ?? this.levelCompleted,
    );
  }

  factory BlockPuzzleState.initial({int size = 8}) {
    final initialCells = _generateInitialFilledCells(size);
    return BlockPuzzleState(
      size: size,
      filledCells: initialCells,
      seedIndices: Set<int>.unmodifiable(initialCells.keys.toSet()),
      availablePieces: generateRandomPieces(),
      selectedPieceId: null,
      score: 0,
      bestScore: 0,
      totalLinesCleared: 0,
      status: BlockGameStatus.playing,
      showPerfectText: false,
      showParticleBurst: false,
      pulseBoard: false,
      showInvalidPlacement: false,
      seedIntroPlayed: false,
      comboCount: 0,
      showComboText: false,
      levelMode: false,
      level: 1,
      levelGoals: const <BlockLevelGoal>[],
      levelTargets: const <int, BlockLevelToken>{},
      levelCompleted: false,
    );
  }
}

class BlockPuzzleNotifier extends StateNotifier<BlockPuzzleState> {
  BlockPuzzleNotifier(this._ref, {bool enablePersistence = true})
      : _enablePersistence = enablePersistence,
        super(BlockPuzzleState.initial()) {
    if (_enablePersistence) {
      unawaited(_restoreState());
    }
  }

  final Ref _ref;
  final bool _enablePersistence;
  static const _stateKey = 'block_puzzle_state';
  static const _bestKey = 'block_puzzle_best';
  static const _seedVersion = 1;

  Timer? _perfectTimer;
  Timer? _particleTimer;
  Timer? _pulseTimer;
  Timer? _errorTimer;
  Timer? _comboTimer;
  final Random _random = Random();

  Future<void> _restoreState() async {
    if (!_enablePersistence) return;
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_bestKey) ?? 0;
    final raw = prefs.getString(_stateKey);
    if (raw == null) {
      state = state.copyWith(bestScore: best);
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final size = decoded['size'] as int? ?? 8;
      final savedSeedVersion = decoded['seedVersion'] as int? ?? 0;
      if (savedSeedVersion < _seedVersion) {
        state = BlockPuzzleState.initial(size: size).copyWith(bestScore: best);
        await _persistState();
        return;
      }
      final filledMap = <int, Color>{};
      final filledRaw = (decoded['filled'] as Map?) ?? {};
      filledRaw.forEach((key, value) {
        final index = int.tryParse(key.toString());
        if (index != null) {
          filledMap[index] = Color(value as int);
        }
      });
      final seedsRaw = decoded['seed'] as List<dynamic>? ?? const [];
      final seedIndices = <int>{};
      for (final entry in seedsRaw) {
        if (entry is int) {
          seedIndices.add(entry);
        } else {
          final parsed = int.tryParse(entry.toString());
          if (parsed != null) {
            seedIndices.add(parsed);
          }
        }
      }
      final seedIntroPlayed = decoded['seedIntroPlayed'] as bool? ?? true;
      final comboCount = decoded['comboCount'] as int? ?? 0;
      final piecesRaw = (decoded['pieces'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => PieceModel.fromJson(e as String))
          .toList();
      final score = decoded['score'] as int? ?? 0;
      final selected = decoded['selected'] as String?;
      state = BlockPuzzleState(
        size: size,
        filledCells: filledMap,
        seedIndices: Set<int>.unmodifiable(seedIndices.isEmpty ? filledMap.keys.toSet() : seedIndices),
        availablePieces: piecesRaw.isEmpty ? generateRandomPieces() : piecesRaw,
        selectedPieceId: selected,
        score: score,
        bestScore: best,
        totalLinesCleared: decoded['lines'] as int? ?? 0,
        status: BlockGameStatus.playing,
        showPerfectText: false,
        showParticleBurst: false,
        pulseBoard: false,
      showInvalidPlacement: false,
      seedIntroPlayed: seedIntroPlayed,
      comboCount: comboCount,
      showComboText: false,
      levelMode: false,
      level: 1,
      levelGoals: const <BlockLevelGoal>[],
      levelTargets: const <int, BlockLevelToken>{},
      levelCompleted: false,
    );
    } catch (_) {
      state = state.copyWith(bestScore: best);
    }
  }

  Future<void> _persistState() async {
    if (!_enablePersistence) return;
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      'size': state.size,
      'score': state.score,
      'selected': state.selectedPieceId,
      'lines': state.totalLinesCleared,
      'filled': state.filledCells.map((key, value) => MapEntry(key.toString(), value.toARGB32())),
      'pieces': state.availablePieces.map((piece) => piece.toJson()).toList(),
      'seedVersion': _seedVersion,
      'seed': state.seedIndices.toList(),
      'seedIntroPlayed': state.seedIntroPlayed,
      'comboCount': state.comboCount,
    };
    await prefs.setString(_stateKey, jsonEncode(map));
    await prefs.setInt(_bestKey, state.bestScore);
  }

  void selectPiece(String pieceId) {
    if (state.status == BlockGameStatus.failed) return;
    state = state.copyWith(selectedPieceId: state.selectedPieceId == pieceId ? null : pieceId);
  }

  bool tryPlaceSelected(int row, int col) {
    final selected = state.selectedPieceId;
    if (selected == null) return false;
    return tryPlacePiece(selected, row, col);
  }

  bool tryPlacePiece(String pieceId, int row, int col) {
    if (state.status == BlockGameStatus.failed) return false;
    if (state.levelMode && state.levelCompleted) return false;
    if (row < 0 || col < 0 || row >= state.size || col >= state.size) {
      _triggerInvalidPlacement();
      return false;
    }
    final piece = _findPiece(pieceId);
    if (piece == null) return false;
    if (!_canPlacePiece(piece, row, col)) {
      _triggerInvalidPlacement();
      return false;
    }

    final updatedCells = Map<int, Color>.from(state.filledCells);
    for (final block in piece.blocks) {
      final targetRow = row + block.rowOffset;
      final targetCol = col + block.colOffset;
      final index = targetRow * state.size + targetCol;
      updatedCells[index] = piece.color;
    }

    final updatedPieces = List<PieceModel>.from(state.availablePieces)..removeWhere((element) => element.id == pieceId);
    if (updatedPieces.isEmpty) {
      updatedPieces.addAll(generateRandomPieces());
    }

    final clearResult = _clearCompletedLines(updatedCells);
    final linesCleared = clearResult.linesCleared;
    final earnedCombo = linesCleared > 0;
    final nextCombo = earnedCombo ? state.comboCount + 1 : 0;
    final showCombo = earnedCombo && nextCombo >= 2;
    final placementScore = piece.cellCount * 5;
    final lineBonus = linesCleared * state.size * 2;
    final newScore = state.score + placementScore + lineBonus;
    final newBest = max(newScore, state.bestScore);
    final totalLines = state.totalLinesCleared + linesCleared;

    var nextStatus = state.status;
    if (!_hasAnyValidMove(updatedPieces, clearResult.cells)) {
      nextStatus = BlockGameStatus.failed;
      _handleGameOver(newScore, totalLines);
    }

    state = state.copyWith(
      filledCells: clearResult.cells,
      availablePieces: updatedPieces,
      selectedPieceId: null,
      score: newScore,
      bestScore: newBest,
      totalLinesCleared: totalLines,
      status: nextStatus,
      showPerfectText: linesCleared >= 2,
      showParticleBurst: linesCleared > 0,
      pulseBoard: true,
      showInvalidPlacement: false,
      comboCount: nextCombo,
      showComboText: showCombo,
    );
    _persistState();
    _handleLevelProgress(clearResult.removedIndices);
    if (showCombo) {
      unawaited(_ref.read(soundControllerProvider).playCombo());
    }
    _scheduleFlagReset(linesCleared >= 2, linesCleared > 0, showCombo);
    return true;
  }

  PieceModel? _findPiece(String id) {
    for (final piece in state.availablePieces) {
      if (piece.id == id) return piece;
    }
    return null;
  }

  bool _canPlacePiece(PieceModel piece, int row, int col) {
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

  _ClearResult _clearCompletedLines(Map<int, Color> cells) {
    final size = state.size;
    final mutable = Map<int, Color>.from(cells);
    final clearedRows = <int>[];
    final clearedCols = <int>[];

    for (var row = 0; row < size; row++) {
      var full = true;
      for (var col = 0; col < size; col++) {
        if (!mutable.containsKey(row * size + col)) {
          full = false;
          break;
        }
      }
      if (full) clearedRows.add(row);
    }

    for (var col = 0; col < size; col++) {
      var full = true;
      for (var row = 0; row < size; row++) {
        if (!mutable.containsKey(row * size + col)) {
          full = false;
          break;
        }
      }
      if (full) clearedCols.add(col);
    }

    if (clearedRows.isEmpty && clearedCols.isEmpty) {
      return _ClearResult(cells: mutable, linesCleared: 0, removedIndices: const <int>{});
    }

    final toRemove = <int>{};
    for (final row in clearedRows) {
      for (var col = 0; col < size; col++) {
        toRemove.add(row * size + col);
      }
    }
    for (final col in clearedCols) {
      for (var row = 0; row < size; row++) {
        toRemove.add(row * size + col);
      }
    }
    toRemove.forEach(mutable.remove);

    return _ClearResult(
      cells: mutable,
      linesCleared: clearedRows.length + clearedCols.length,
      removedIndices: toRemove,
    );
  }

  bool _hasAnyValidMove(List<PieceModel> pieces, Map<int, Color> filled) {
    final size = state.size;
    for (final piece in pieces) {
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          var fits = true;
          for (final block in piece.blocks) {
            final targetRow = row + block.rowOffset;
            final targetCol = col + block.colOffset;
            if (targetRow >= size || targetCol >= size) {
              fits = false;
              break;
            }
            if (targetRow < 0 || targetCol < 0) {
              fits = false;
              break;
            }
            final index = targetRow * size + targetCol;
            if (filled.containsKey(index)) {
              fits = false;
              break;
            }
          }
          if (fits) return true;
        }
      }
    }
    return false;
  }

  void _scheduleFlagReset(bool perfect, bool particles, bool comboActive) {
    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(milliseconds: 260), () {
      state = state.copyWith(pulseBoard: false);
    });
    if (perfect) {
      _perfectTimer?.cancel();
      _perfectTimer = Timer(const Duration(milliseconds: 1200), () {
        state = state.copyWith(showPerfectText: false);
      });
    } else if (state.showPerfectText) {
      state = state.copyWith(showPerfectText: false);
    }
    if (particles) {
      _particleTimer?.cancel();
      _particleTimer = Timer(const Duration(milliseconds: 600), () {
        state = state.copyWith(showParticleBurst: false);
      });
    } else if (state.showParticleBurst) {
      state = state.copyWith(showParticleBurst: false);
    }
    if (comboActive) {
      _comboTimer?.cancel();
      _comboTimer = Timer(const Duration(milliseconds: 1400), () {
        state = state.copyWith(showComboText: false, comboCount: state.comboCount);
      });
    } else if (state.showComboText) {
      _comboTimer?.cancel();
      state = state.copyWith(showComboText: false, comboCount: state.comboCount);
    }
  }

  void restart({int? size}) {
    _perfectTimer?.cancel();
    _particleTimer?.cancel();
    _pulseTimer?.cancel();
    _errorTimer?.cancel();
    _comboTimer?.cancel();
    if (state.levelMode) {
      startLevelChallenge(level: state.level);
      return;
    }
    state = BlockPuzzleState.initial(size: size ?? state.size).copyWith(bestScore: state.bestScore);
    _persistState();
  }

  void changeBoardSize(int newSize) {
    if (state.levelMode) return;
    restart(size: newSize);
  }

  void startLevelChallenge({int level = 1}) {
    final normalized = level.clamp(1, 99);
    final size = 8;
    final goals = _buildLevelGoals(normalized);
    final tokens = _generateLevelTargets(size: size, goals: goals, level: normalized);
    final obstacles = _generateLevelObstacles(size: size, exclude: tokens.keys.toSet(), level: normalized);
    final filled = <int, Color>{};
    tokens.forEach((index, token) {
      filled[index] = token.color;
    });
    for (final index in obstacles) {
      filled[index] = const Color(0xFF9B6A3C);
    }
    state = BlockPuzzleState.initial(size: size).copyWith(
      filledCells: filled,
      seedIndices: {...tokens.keys, ...obstacles},
      score: 0,
      totalLinesCleared: 0,
      status: BlockGameStatus.playing,
      showPerfectText: false,
      showParticleBurst: false,
      pulseBoard: false,
      showInvalidPlacement: false,
      comboCount: 0,
      showComboText: false,
      levelMode: true,
      level: normalized,
      levelGoals: goals,
      levelTargets: tokens,
      levelCompleted: false,
      bestScore: state.bestScore,
    );
  }

  void nextLevelChallenge() {
    startLevelChallenge(level: state.level + 1);
  }

  void markSeedIntroPlayed() {
    if (state.seedIntroPlayed) return;
    state = state.copyWith(seedIntroPlayed: true);
    _persistState();
  }

  void _handleGameOver(int score, int linesCleared) {
    if (state.levelMode) {
      state = state.copyWith(status: BlockGameStatus.failed);
      return;
    }
    final entry = BlockLeaderboardEntry(
      name: 'Blocker',
      score: score,
      linesCleared: linesCleared,
      completedAt: DateTime.now(),
    );
    unawaited(_ref.read(blockLeaderboardProvider.notifier).addEntry(entry));
    unawaited(_ref.read(soundControllerProvider).playFailure());
  }

  @override
  void dispose() {
    _perfectTimer?.cancel();
    _particleTimer?.cancel();
    _pulseTimer?.cancel();
    _errorTimer?.cancel();
    _comboTimer?.cancel();
    super.dispose();
  }

  void _triggerInvalidPlacement() {
    _errorTimer?.cancel();
    state = state.copyWith(showInvalidPlacement: true);
    _errorTimer = Timer(const Duration(milliseconds: 900), () {
      state = state.copyWith(showInvalidPlacement: false);
    });
  }

  List<BlockLevelGoal> _buildLevelGoals(int level) {
    final tokens = List<BlockLevelToken>.from(BlockLevelToken.values)..shuffle(_random);
    final progress = (level - 1).clamp(0, 98) / 98;
    final base = 3 + (progress * 5).floor(); // 3 -> 8
    final spread = 1 + (progress * 3).floor(); // 1 -> 4
    final bonus = (level ~/ 15).clamp(0, 4);
    return List.generate(3, (index) {
      final token = tokens[index % tokens.length];
      final required = (base + (index * spread) + bonus).clamp(3, 24);
      return BlockLevelGoal(token: token, required: required, remaining: required);
    });
  }

  Map<int, BlockLevelToken> _generateLevelTargets({
    required int size,
    required List<BlockLevelGoal> goals,
    required int level,
  }) {
    final totalCells = size * size;
    final indices = List<int>.generate(totalCells, (index) => index)..shuffle(_random);
    final targets = <int, BlockLevelToken>{};
    final padding = max(0, 4 - level ~/ 10);
    var cursor = 0;
    for (final goal in goals) {
      final available = indices.length - cursor;
      if (available <= 0) break;
      final quota = min(goal.required + padding, available);
      for (var i = 0; i < quota; i++) {
        final idx = indices[cursor++];
        targets[idx] = goal.token;
      }
    }
    return targets;
  }

  Set<int> _generateLevelObstacles({required int size, required Set<int> exclude, required int level}) {
    final totalCells = size * size;
    final indices = List<int>.generate(totalCells, (index) => index)..shuffle(_random);
    final progress = (level - 1).clamp(0, 98) / 98;
    final ratio = 0.12 + (progress * 0.15); // 12% -> 27%
    final targetCount = max(4, (totalCells * ratio).round());
    final obstacles = <int>{};
    for (final index in indices) {
      if (exclude.contains(index)) continue;
      obstacles.add(index);
      if (obstacles.length >= targetCount) break;
    }
    return obstacles;
  }

  void _handleLevelProgress(Set<int> removedIndices) {
    if (!state.levelMode || removedIndices.isEmpty || state.levelTargets.isEmpty) {
      return;
    }
    final targets = Map<int, BlockLevelToken>.from(state.levelTargets);
    final removedCounts = <BlockLevelToken, int>{};
    for (final index in removedIndices) {
      final token = targets.remove(index);
      if (token != null) {
        removedCounts[token] = (removedCounts[token] ?? 0) + 1;
      }
    }
    if (removedCounts.isEmpty) {
      state = state.copyWith(levelTargets: targets);
      return;
    }
    final updatedGoals = state.levelGoals
        .map(
          (goal) => removedCounts.containsKey(goal.token) ? goal.decrement(removedCounts[goal.token]!) : goal,
        )
        .toList();
    final completed = updatedGoals.every((goal) => goal.isComplete);
    state = state.copyWith(
      levelGoals: updatedGoals,
      levelTargets: targets,
      levelCompleted: completed,
      showPerfectText: completed || state.showPerfectText,
      showParticleBurst: completed || state.showParticleBurst,
    );
    if (completed) {
      unawaited(_ref.read(soundControllerProvider).playSuccess());
    }
  }
}

class _ClearResult {
  const _ClearResult({
    required this.cells,
    required this.linesCleared,
    required this.removedIndices,
  });

  final Map<int, Color> cells;
  final int linesCleared;
  final Set<int> removedIndices;
}

const List<Color> _seedBoardColors = [
  Color(0xFFB37744),
  Color(0xFFCB9A63),
  Color(0xFF8B5130),
  Color(0xFF6E3A23),
  Color(0xFFD4AF8A),
];

Map<int, Color> _generateInitialFilledCells(int size) {
  if (size <= 0) return {};
  final total = size * size;
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  final empties = <int>{};

  void markEmpty(int row, int col) {
    if (row < 0 || col < 0 || row >= size || col >= size) return;
    empties.add(row * size + col);
  }

  for (var row = 0; row < size; row++) {
    final col = random.nextInt(size);
    markEmpty(row, col);
    if (random.nextBool()) {
      markEmpty(row, (col + 1) % size);
    }
  }

  for (var col = 0; col < size; col++) {
    final row = random.nextInt(size);
    markEmpty(row, col);
    if (random.nextBool()) {
      markEmpty((row + 1) % size, col);
    }
  }
  //TODO boş gelen kutuların sayısı
  final targetEmpty = max((total * 0.65).round(), size * 6);
  while (empties.length < targetEmpty) {
    final index = random.nextInt(total);
    final row = index ~/ size;
    final col = index % size;
    markEmpty(row, col);
    if (random.nextBool()) {
      markEmpty(row, (col + 1) % size);
    }
    if (random.nextInt(3) == 0) {
      markEmpty((row + 1) % size, col);
    }
  }

  final cells = <int, Color>{};
  for (var index = 0; index < total; index++) {
    if (empties.contains(index)) continue;
    cells[index] = _seedBoardColors[random.nextInt(_seedBoardColors.length)];
  }

  return cells;
}
