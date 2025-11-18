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

const String kBlockLevelProgressKey = 'block_level_progress';

final blockPuzzleProvider = StateNotifierProvider<BlockPuzzleNotifier, BlockPuzzleState>(
  (ref) => BlockPuzzleNotifier(ref),
);

enum BlockGameStatus { playing, failed }

const _selectionSentinel = Object();
const double _levelEmptyCellRatio = 0.47;
const double _levelObstacleRatio = 0.08;
const int _levelMinObstacleCount = 3;
const int _extraTokensPerGoal = 2;
const Duration _blockExplosionDuration = Duration(milliseconds: 600);

class BlockExplosionEffect {
  const BlockExplosionEffect({
    required this.id,
    required this.index,
    required this.color,
  });

  final int id;
  final int index;
  final Color color;
}

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
    required this.blockExplosions,
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
  final List<BlockExplosionEffect> blockExplosions;

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
    List<BlockExplosionEffect>? blockExplosions,
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
      blockExplosions: blockExplosions ?? this.blockExplosions,
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
      blockExplosions: const <BlockExplosionEffect>[],
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
        blockExplosions: const <BlockExplosionEffect>[],
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
    final newExplosions = clearResult.removedCells.entries
        .map(
          (entry) => BlockExplosionEffect(
            id: DateTime.now().microsecondsSinceEpoch + entry.key + _random.nextInt(1000),
            index: entry.key,
            color: entry.value,
          ),
        )
        .toList(growable: false);
    final explosionQueue = List<BlockExplosionEffect>.unmodifiable([
      ...state.blockExplosions,
      ...newExplosions,
    ]);
    final linesCleared = clearResult.linesCleared;
    final earnedCombo = linesCleared > 0;
    final triggeredPerfect = linesCleared >= 2;
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
      showPerfectText: triggeredPerfect,
      showParticleBurst: linesCleared > 0,
      pulseBoard: true,
      showInvalidPlacement: false,
      comboCount: nextCombo,
      showComboText: showCombo,
      blockExplosions: explosionQueue,
    );
    _persistState();
    if (triggeredPerfect) {
      unawaited(_ref.read(soundControllerProvider).playPerfect());
    }
    _handleLevelProgress(clearResult.removedIndices);
    if (showCombo) {
      unawaited(_ref.read(soundControllerProvider).playCombo());
    }
    _scheduleFlagReset(linesCleared >= 2, linesCleared > 0, showCombo);
    for (final effect in newExplosions) {
      _scheduleExplosionCleanup(effect.id);
    }
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
      return _ClearResult(
        cells: mutable,
        linesCleared: 0,
        removedIndices: const <int>{},
        removedCells: const <int, Color>{},
      );
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
    final removedColors = <int, Color>{};
    for (final index in toRemove) {
      final color = cells[index];
      if (color != null) {
        removedColors[index] = color;
      }
      mutable.remove(index);
    }

    return _ClearResult(
      cells: mutable,
      linesCleared: clearedRows.length + clearedCols.length,
      removedIndices: toRemove,
      removedCells: removedColors,
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

  void _scheduleExplosionCleanup(int id) {
    Future.delayed(_blockExplosionDuration, () {
      if (!mounted) return;
      final filtered = state.blockExplosions.where((effect) => effect.id != id).toList(growable: false);
      if (filtered.length == state.blockExplosions.length) return;
      state = state.copyWith(blockExplosions: List<BlockExplosionEffect>.unmodifiable(filtered));
    });
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
    final totalCells = size * size;
    final minTokenBudget = goals.fold<int>(0, (sum, goal) => sum + goal.required);
    final maxEmptyCells = totalCells - minTokenBudget;
    final desiredEmptyCells = (totalCells * _levelEmptyCellRatio).round();
    final initialEmptyCells = min(desiredEmptyCells, maxEmptyCells);
    final targetEmptyCells = max(0, min(initialEmptyCells, totalCells));
    final targetFilledCells = totalCells - targetEmptyCells;
    final desiredObstacleCount = max(_levelMinObstacleCount, (totalCells * _levelObstacleRatio).round());
    final paddedTokenBudget = minTokenBudget + (goals.length * _extraTokensPerGoal);
    final baseTokenBudget = max(targetFilledCells - desiredObstacleCount, paddedTokenBudget);
    final tokenBudget = min(targetFilledCells, baseTokenBudget);
    final obstacleBudget = targetFilledCells - tokenBudget;
    final tokens = _generateLevelTargets(
      size: size,
      goals: goals,
      tokenBudget: tokenBudget,
    );
    final obstacles = _generateLevelObstacles(
      size: size,
      exclude: tokens.keys.toSet(),
      count: obstacleBudget,
    );
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
    const baseRequirements = [1, 2, 2];
    final adjusted = List<int>.from(baseRequirements);
    final increments = max(0, level - 1);
    for (var i = 0; i < increments; i++) {
      adjusted[i % adjusted.length]++;
    }
    return List.generate(adjusted.length, (index) {
      final token = tokens[index % tokens.length];
      final required = adjusted[index];
      return BlockLevelGoal(token: token, required: required, remaining: required);
    });
  }

  Map<int, BlockLevelToken> _generateLevelTargets({
    required int size,
    required List<BlockLevelGoal> goals,
    required int tokenBudget,
  }) {
    final targets = <int, BlockLevelToken>{};
    if (tokenBudget <= 0 || goals.isEmpty) return targets;
    final used = <int>{};
    final totalRequired = goals.fold<int>(0, (sum, goal) => sum + goal.required);
    final extraCells = max(0, tokenBudget - totalRequired);
    final basePadding = extraCells ~/ goals.length;
    var remainder = extraCells % goals.length;
    var remainingBudget = tokenBudget;
    for (final goal in goals) {
      if (remainingBudget <= 0) break;
      final additional = basePadding + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      final remainingCells = (size * size) - used.length;
      if (remainingCells <= 0) break;
      final quota = min(goal.required + additional, min(remainingBudget, remainingCells));
      if (quota <= 0) continue;
      final cluster = _claimClusterIndices(
        size: size,
        count: quota,
        used: used,
        random: _random,
        scatterProbability: 0.45,
      );
      for (final index in cluster) {
        targets[index] = goal.token;
        used.add(index);
      }
      remainingBudget = max(0, remainingBudget - cluster.length);
    }
    return targets;
  }

  Set<int> _generateLevelObstacles({required int size, required Set<int> exclude, required int count}) {
    final totalCells = size * size;
    final targetCount = max(0, min(count, totalCells - exclude.length));
    final used = exclude.toSet();
    final cluster = _claimClusterIndices(
      size: size,
      count: targetCount,
      used: used,
      random: _random,
      scatterProbability: 0.4,
    );
    final obstacles = cluster.toSet();
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
    final unlockedLevel = state.level + 1;
    final alreadyCompleted = state.levelCompleted;
    state = state.copyWith(
      levelGoals: updatedGoals,
      levelTargets: targets,
      levelCompleted: completed,
      showPerfectText: completed || state.showPerfectText,
      showParticleBurst: completed || state.showParticleBurst,
    );
    if (completed && !alreadyCompleted) {
      final soundController = _ref.read(soundControllerProvider);
      unawaited(soundController.playSuccess());
      unawaited(soundController.playLevelUp());
      unawaited(_updateLevelProgress(unlockedLevel));
    }
  }

  Future<void> _updateLevelProgress(int unlockedLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(kBlockLevelProgressKey) ?? 1;
    final target = unlockedLevel.clamp(1, 99);
    if (target > current) {
      await prefs.setInt(kBlockLevelProgressKey, target);
    }
  }
}

class _ClearResult {
  const _ClearResult({
    required this.cells,
    required this.linesCleared,
    required this.removedIndices,
    required this.removedCells,
  });

  final Map<int, Color> cells;
  final int linesCleared;
  final Set<int> removedIndices;
  final Map<int, Color> removedCells;
}

const List<Color> _seedBoardColors = [
  Color(0xFFB37744),
  Color(0xFFCB9A63),
  Color(0xFF8B5130),
  Color(0xFF6E3A23),
  Color(0xFFD4AF8A),
];

List<int> _adjacentIndices(int index, int size, {bool includeDiagonals = false}) {
  final row = index ~/ size;
  final col = index % size;
  final neighbors = <int>[];
  void tryAdd(int r, int c) {
    if (r < 0 || c < 0 || r >= size || c >= size) return;
    neighbors.add(r * size + c);
  }

  tryAdd(row - 1, col);
  tryAdd(row + 1, col);
  tryAdd(row, col - 1);
  tryAdd(row, col + 1);
  if (includeDiagonals) {
    tryAdd(row - 1, col - 1);
    tryAdd(row - 1, col + 1);
    tryAdd(row + 1, col - 1);
    tryAdd(row + 1, col + 1);
  }
  return neighbors;
}

List<int> _claimClusterIndices({
  required int size,
  required int count,
  required Set<int> used,
  required Random random,
  double scatterProbability = 0.35,
  bool allowDiagonalAdjacency = false,
}) {
  if (count <= 0) return const [];
  final totalCells = size * size;
  if (used.length >= totalCells) return const [];
  final scatter = scatterProbability.clamp(0.0, 1.0).toDouble();
  final claimed = <int>[];
  final visited = <int>{};
  final available = List<int>.generate(totalCells, (index) => index)..shuffle(random);
  var availableCursor = 0;
  final frontier = <int>[];

  int? nextSeed() {
    while (availableCursor < available.length) {
      final candidate = available[availableCursor++];
      if (!used.contains(candidate) && !claimed.contains(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  void enqueueSeed(int? seed) {
    if (seed == null) return;
    if (used.contains(seed) || claimed.contains(seed) || visited.contains(seed)) return;
    frontier.add(seed);
  }

  void ensureSeed() {
    if (frontier.isEmpty) {
      enqueueSeed(nextSeed());
    }
  }

  enqueueSeed(nextSeed());

  while (claimed.length < count) {
    ensureSeed();
    if (frontier.isEmpty) break;
    final current = frontier.removeAt(random.nextInt(frontier.length));
    if (used.contains(current) || !visited.add(current)) continue;
    claimed.add(current);
    final neighbors = _adjacentIndices(current, size, includeDiagonals: allowDiagonalAdjacency)..shuffle(random);
    for (final neighbor in neighbors) {
      if (used.contains(neighbor) || visited.contains(neighbor) || claimed.contains(neighbor)) continue;
      if (random.nextDouble() >= scatter) {
        frontier.add(neighbor);
      } else {
        enqueueSeed(nextSeed());
      }
    }
    if (random.nextDouble() < scatter) {
      enqueueSeed(nextSeed());
    }
  }

  return claimed;
}

Map<int, Color> _generateInitialFilledCells(int size) {
  if (size <= 0) return {};
  final total = size * size;
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  final minFilled = size * 4;
  final maxFilled = (total * 0.6).round();
  final desired = (total * 0.45).round();
  final targetFilled = min(maxFilled, max(minFilled, desired));
  final clusterSeedCount = max(3, size ~/ 2);
  final clusterMinSize = max(6, size);
  final clusterMaxSize = max(clusterMinSize + 4, size * 2);
  final filled = <int>{};

  List<int> neighborsOf(int index) {
    final row = index ~/ size;
    final col = index % size;
    final neighbors = <int>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nc < 0 || nr >= size || nc >= size) continue;
        neighbors.add(nr * size + nc);
      }
    }
    return neighbors;
  }

  void growCluster(int start) {
    if (filled.contains(start)) return;
    final span = clusterMaxSize - clusterMinSize;
    final clusterTarget = min(
      targetFilled - filled.length,
      clusterMinSize + (span <= 0 ? 0 : random.nextInt(span + 1)),
    );
    final queue = <int>[start];
    final visited = <int>{};
    var produced = 0;
    while (queue.isNotEmpty && filled.length < targetFilled && produced < clusterTarget) {
      final current = queue.removeAt(random.nextInt(queue.length));
      if (!visited.add(current) || filled.contains(current)) continue;
      filled.add(current);
      produced++;
      final neighbors = neighborsOf(current)..shuffle(random);
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor) && random.nextDouble() > 0.35) {
          queue.add(neighbor);
        }
      }
    }
  }

  for (var i = 0; i < clusterSeedCount && filled.length < targetFilled; i++) {
    growCluster(random.nextInt(total));
  }

  while (filled.length < targetFilled) {
    if (filled.isEmpty) {
      filled.add(random.nextInt(total));
      continue;
    }
    final anchor = filled.elementAt(random.nextInt(filled.length));
    final neighbors = neighborsOf(anchor);
    if (neighbors.isEmpty) {
      filled.add(random.nextInt(total));
    } else {
      neighbors.shuffle(random);
      filled.add(neighbors.first);
    }
  }

  final cells = <int, Color>{};
  for (final index in filled) {
    cells[index] = _seedBoardColors[random.nextInt(_seedBoardColors.length)];
  }
  return cells;
}
