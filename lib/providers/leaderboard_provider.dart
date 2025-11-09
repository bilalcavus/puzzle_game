import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/leaderboard_entry.dart';

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, AsyncValue<List<LeaderboardEntry>>>(
  (ref) => LeaderboardNotifier()..loadEntries(),
);

class LeaderboardNotifier extends StateNotifier<AsyncValue<List<LeaderboardEntry>>> {
  LeaderboardNotifier() : super(const AsyncValue.loading());

  static const _storageKey = 'puzzle_leaderboard';

  Future<void> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey) ?? <String>[];
      final entries = stored.map(LeaderboardEntry.fromJson).toList()
        ..sort((a, b) => a.moves.compareTo(b.moves));
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addEntry(LeaderboardEntry entry) async {
    final current = state.value ?? <LeaderboardEntry>[];
    final updated = [...current, entry]
      ..sort((a, b) {
        final moveCompare = a.moves.compareTo(b.moves);
        return moveCompare != 0 ? moveCompare : a.duration.compareTo(b.duration);
      });
    final trimmed = updated.take(5).toList();
    state = AsyncValue.data(trimmed);

    final prefs = await SharedPreferences.getInstance();
    final serialized = trimmed.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, serialized);
  }
}
