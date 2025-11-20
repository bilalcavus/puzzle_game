import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/block_leaderboard_provider.dart';

class BlockLeaderboardView extends ConsumerWidget {
  const BlockLeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(blockLeaderboardProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr('leaderboard.block.title'))),
      body: leaderboard.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text(tr('leaderboard.block.empty')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                title: Text('${index + 1}. ${entry.name}'),
                subtitle: Text(
                  tr(
                    'leaderboard.lines',
                    namedArgs: {'count': '${entry.linesCleared}'},
                  ),
                ),
                trailing: Text(
                  tr(
                    'leaderboard.points',
                    namedArgs: {'points': '${entry.score}'},
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: entries.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(tr('leaderboard.error', namedArgs: {'error': '$error'})),
        ),
      ),
    );
  }
}
