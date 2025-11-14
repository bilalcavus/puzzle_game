import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/block_puzzle_level_provider.dart';
import '../../providers/block_puzzle_provider.dart';
import 'block_level_game_view.dart';
import 'widgets/block_background.dart';

class LevelPathView extends ConsumerWidget {
  const LevelPathView({super.key});

  static const int _previewCount = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: BlockPuzzleBackground(
        child: SafeArea(
          child: Padding(
            padding: context.padding.low,
            child: FutureBuilder<int>(
              future: _loadProgress(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final unlockedLevel = snapshot.data!.clamp(1, 99);
                final currentState = ref.watch(blockPuzzleLevelProvider);
                final currentLevel = currentState.level;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 3,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 109, 91, 65).withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ),
                              ListView.builder(
                                padding: context.padding.verticalLow,
                                itemCount: _previewCount,
                                itemBuilder: (context, index) {
                                  final level = index + 1;
                                  final unlocked = level <= unlockedLevel;
                                  final current = level == currentLevel;
                                  final alignLeft = index.isEven;
                                  final stars = level < unlockedLevel ? 3 : 0;
                                  return SizedBox(
                                    height: context.dynamicHeight(0.15),
                                    child: Align(
                                      alignment: Alignment(alignLeft ? -0.65 : 0.65, 0),
                                      child: _LevelBadge(
                                        level: level,
                                        stars: stars,
                                        unlocked: unlocked,
                                        current: current,
                                        onTap: unlocked
                                            ? () {
                                                ref.read(blockPuzzleLevelProvider.notifier).startLevelChallenge(level: level);
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => const BlockPuzzleLevelGameView()),
                                                );
                                              }
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<int> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(kBlockLevelProgressKey) ?? 1;
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.onTap,
  });

  final int level;
  final int stars;
  final bool unlocked;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final circleColor = current
        ? Colors.amberAccent
        : unlocked
            ? const Color(0xFFCCA27A)
            : const Color(0xFFC8BFB6);
    final borderColor = current ? Colors.amber : Colors.brown.shade500;
    final textColor = current ? Colors.black : Colors.brown.shade800;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: context.dynamicHeight(0.1),
            height: context.dynamicHeight(0.1),
            decoration: BoxDecoration(
              color: circleColor,
              borderRadius: context.border.normalBorderRadius,
              border: Border.all(color: borderColor, width: current ? 5 : 3),
              boxShadow: current
                  ? const [BoxShadow(color: Colors.amberAccent, blurRadius: 18, offset: Offset(0, 8))]
                  : const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$level',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (current)
                    Text(
                      'CURRENT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.brown.shade700),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (unlocked)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final filled = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 16,
                    color: filled ? Colors.green.shade600 : Colors.brown.shade200,
                  ),
                );
              }),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.lock, size: 18, color: Colors.brown.shade200),
            ),
        ],
      ),
    );
  }
}
