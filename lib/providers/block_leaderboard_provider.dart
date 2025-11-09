import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/block_leaderboard_entry.dart';

final blockLeaderboardProvider = StateNotifierProvider<BlockLeaderboardNotifier, AsyncValue<List<BlockLeaderboardEntry>>>(
  (ref) => BlockLeaderboardNotifier()..loadEntries(),
);

class BlockLeaderboardNotifier extends StateNotifier<AsyncValue<List<BlockLeaderboardEntry>>> {
  BlockLeaderboardNotifier() : super(const AsyncValue.loading());

  static const _storageKey = 'block_puzzle_leaderboard';

  Future<void> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey) ?? <String>[];
      final entries = stored.map(BlockLeaderboardEntry.fromJson).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addEntry(BlockLeaderboardEntry entry) async {
    final current = state.value ?? <BlockLeaderboardEntry>[];
    final updated = [...current, entry]
      ..sort((a, b) => b.score.compareTo(a.score));
    final trimmed = updated.take(10).toList();
    state = AsyncValue.data(trimmed);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, trimmed.map((e) => e.toJson()).toList());
  }
}
