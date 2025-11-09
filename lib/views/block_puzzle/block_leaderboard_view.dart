import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/block_leaderboard_provider.dart';

class BlockLeaderboardView extends ConsumerWidget {
  const BlockLeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(blockLeaderboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wooden Leaderboard')),
      body: leaderboard.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Play a round to record your first score.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                title: Text('${index + 1}. ${entry.name}'),
                subtitle: Text('Lines: ${entry.linesCleared}'),
                trailing: Text('${entry.score} pts'),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: entries.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load leaderboard: $error')),
      ),
    );
  }
}
