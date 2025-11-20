import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../views/block_puzzle/block_mode_view.dart';
import '../../widgets/components/locale_menu_button.dart';
import '../game/game_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [LocaleMenuButton()],
            ),
            const SizedBox(height: 16),
            Text(
              tr('home.title'),
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tr('home.subtitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            _GameCard(
              title: tr('home.cards.sliding.title'),
              description: tr('home.cards.sliding.description'),
              color: Colors.deepPurple,
              icon: Icons.grid_4x4,
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GameView())),
            ),
            const SizedBox(height: 16),
            _GameCard(
              title: tr('home.cards.block.title'),
              description: tr('home.cards.block.description'),
              color: Colors.teal,
              icon: Icons.crop_square,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlockPuzzleModeView()),
              ),
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
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onPressed, child: Text(tr('common.play'))),
        ],
      ),
    );
  }
}
