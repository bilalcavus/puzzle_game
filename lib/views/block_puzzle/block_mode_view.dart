import 'package:flutter/material.dart';

import 'block_puzzle_view.dart';
import 'level_path_view.dart';

class BlockPuzzleModeView extends StatelessWidget {
  const BlockPuzzleModeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wooden Block Modes')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModeCard(
              title: 'Klasik 8x8 & 10x10',
              description:
                  'Sonsuz modda puan kovala, 8x8 ve 10x10 tahtalar arasında geçiş yaparak rekorunu kır.',
              color: Colors.teal,
              icon: Icons.grid_on,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) =>  BlockPuzzleGameView()),
                );
              },
            ),
            const SizedBox(height: 24),
            _ModeCard(
              title: 'Level 1-99',
              description:
                  'Üç özel şeklin hedef sayılarını sıfırla, patlayan kutularla jungle parkurunda 99. levele kadar ilerle.',
              color: Colors.deepOrange,
              icon: Icons.auto_awesome_motion,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LevelPathView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
