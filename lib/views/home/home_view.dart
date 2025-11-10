import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../views/block_puzzle/block_puzzle_view.dart';
import '../../providers/block_puzzle_provider.dart';
import '../game/game_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Text(
              'Puzzle Arcade',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a challenge: classic sliding logic or the new wooden block adventure.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            _GameCard(
              title: 'Sliding Puzzle',
              description: 'Classic 4x4 tile slider with timers, leaderboards, haptics, and smooth animations.',
              color: Colors.deepPurple,
              icon: Icons.grid_4x4,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameView()),
              ),
            ),
            const SizedBox(height: 16),
            _GameCard(
              title: 'Wooden Block Puzzle',
              description: 'Drag wooden pieces onto a jungle board, clear rows for sparkles, and chase the perfect combo.',
              color: Colors.teal,
              icon: Icons.crop_square,
              onPressed: () {
                ref.read(blockPuzzleProvider.notifier).restart();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BlockPuzzleGameView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }
}
