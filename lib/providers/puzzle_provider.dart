import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';
import '../models/puzzle_model.dart';
import '../core/utils/puzzle_shuffle.dart';
import '../core/utils/puzzle_timer.dart';
import 'leaderboard_provider.dart';

final puzzleProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>(
  (ref) => PuzzleNotifier(ref),
);

enum GameStatus { idle, playing, completed }

class PuzzleState {
  const PuzzleState({
    required this.puzzle,
    required this.elapsed,
    required this.moves,
    required this.status,
    required this.level,
    required this.showVictory,
  });

  final PuzzleModel puzzle;
  final Duration elapsed;
  final int moves;
  final GameStatus status;
  final int level;
  final bool showVictory;

  factory PuzzleState.initial({required int size}) {
    return PuzzleState(
      puzzle: PuzzleModel.empty(size),
      elapsed: Duration.zero,
      moves: 0,
      status: GameStatus.idle,
      level: 1,
      showVictory: false,
    );
  }

  PuzzleState copyWith({
    PuzzleModel? puzzle,
    Duration? elapsed,
    int? moves,
    GameStatus? status,
    int? level,
    bool? showVictory,
  }) {
    return PuzzleState(
      puzzle: puzzle ?? this.puzzle,
      elapsed: elapsed ?? this.elapsed,
      moves: moves ?? this.moves,
      status: status ?? this.status,
      level: level ?? this.level,
      showVictory: showVictory ?? this.showVictory,
    );
  }

  String get formattedTime {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier(this._ref) : super(PuzzleState.initial(size: _boardSize)) {
    shuffle();
  }

  static const int _boardSize = 4;
  final Ref _ref;
  final PuzzleTimerHelper _timerHelper = PuzzleTimerHelper();

  void shuffle() {
    final sequence = generateSolvableSequence(_boardSize);
    final puzzle = PuzzleModel.fromSequence(size: _boardSize, sequence: sequence);
    _timerHelper.reset();
    state = state.copyWith(
      puzzle: puzzle,
      elapsed: Duration.zero,
      moves: 0,
      status: GameStatus.idle,
      showVictory: false,
    );
  }

  void start() {
    if (state.status == GameStatus.playing) return;
    _timerHelper.start((elapsed) {
      state = state.copyWith(elapsed: elapsed);
    });
    state = state.copyWith(status: GameStatus.playing);
  }

  bool tryMove(int tileValue) {
    final tile = state.puzzle.tileByValue(tileValue);
    if (!state.puzzle.canMove(tile)) {
      return false;
    }
    if (state.status == GameStatus.idle) {
      start();
    }
    final updatedPuzzle = state.puzzle.moveTile(tile);
    final moves = state.moves + 1;
    state = state.copyWith(puzzle: updatedPuzzle, moves: moves);
    if (updatedPuzzle.isSolved) {
      _completePuzzle();
    }
    return true;
  }

  void restart() {
    shuffle();
  }

  void nextLevel() {
    final nextLevel = state.level + 1;
    shuffle();
    state = state.copyWith(level: nextLevel);
  }

  void dismissVictory() {
    state = state.copyWith(showVictory: false);
  }

  void _completePuzzle() {
    _timerHelper.stop();
    final completedState = state.copyWith(status: GameStatus.completed, showVictory: true);
    state = completedState;
    final entry = LeaderboardEntry(
      name: 'Player',
      moves: completedState.moves,
      duration: completedState.elapsed,
      completedAt: DateTime.now(),
    );
    unawaited(_ref.read(leaderboardProvider.notifier).addEntry(entry));
  }

  @override
  void dispose() {
    _timerHelper.dispose();
    super.dispose();
  }
}
