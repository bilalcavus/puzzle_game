import 'package:flutter/material.dart';

import '../../widgets/components/app_button.dart';
import '../game/game_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Sliding Puzzle',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Arrange the tiles into order on the 4x4 board. Drag or tap tiles beside the empty slot, beat the timer, and climb the local leaderboard.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              AppButton(
                label: 'Start Playing',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameView()),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
