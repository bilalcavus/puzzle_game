import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/core/extension/sized_box.dart';
import 'package:puzzle_game/views/block_puzzle/block_puzzle_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/block_puzzle_level_provider.dart';
import '../../providers/block_puzzle_provider.dart';
import 'block_level_game_view.dart';

class LevelPathView extends ConsumerWidget {
  const LevelPathView({super.key});

  static const List<int> _rowOccupancy = [1, 4, 6, 8, 10, 10, 10, 10, 8, 8, 6, 6, 4, 3, 2];
  static const int _columns = 10;
  static final List<List<int?>> _levelGrid = _buildLevelGrid();
  static final int _totalLevels = _rowOccupancy.fold(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FutureBuilder<int>(
        future: _loadProgress(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ColoredBox(
              color: Color(0xFFb37a45),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final unlockedLevel = snapshot.data!.clamp(1, _totalLevels);
          // Highlight the furthest level reached/unlocked.
          final currentLevel = unlockedLevel;

          void handleLevelTap(int level) {
            ref.read(blockPuzzleLevelProvider.notifier).startLevelChallenge(level: level);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlockPuzzleLevelGameView()));
          }

          return _LevelPathBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _LevelPathHeader(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 24),
                    _TrophyIntro(),
                    context.dynamicHeight(0.02).height,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            _AdventureBoard(grid: _levelGrid, unlockedLevel: unlockedLevel, currentLevel: currentLevel, onLevelTap: handleLevelTap),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BottomBar(highestLevel: unlockedLevel, onJump: () => handleLevelTap(unlockedLevel)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static List<List<int?>> _buildLevelGrid() {
    final rows = _rowOccupancy.length;
    final grid = List<List<int?>>.generate(rows, (_) => List<int?>.filled(_columns, null));
    int level = 1;

    for (int row = rows - 1; row >= 0; row--) {
      final count = _rowOccupancy[row];
      final startIndex = ((_columns - count) / 2).floor();
      for (int offset = 0; offset < count; offset++) {
        grid[row][startIndex + offset] = level++;
      }
    }

    return grid;
  }

  Future<int> _loadProgress() async {
    if (kDebugMode) return _totalLevels;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(kBlockLevelProgressKey) ?? 1;
  }
}

class _LevelPathBackground extends StatelessWidget {
  const _LevelPathBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlockPuzzleBackground(child: child);
    // DecoratedBox(
    //   decoration: const BoxDecoration(
    //     gradient: LinearGradient(
    //       begin: Alignment.topCenter,
    //       end: Alignment.bottomCenter,
    //       colors: [Color(0xFFd79b58), Color(0xFFa2612e)],
    //     ),
    //   ),
    //   child: Stack(
    //     children: [
    //       Positioned.fill(
    //         child: Opacity(
    //           opacity: 0.08,
    //           child: Image.asset(
    //             'assets/images/wood-asset.png',
    //             repeat: ImageRepeat.repeat,
    //             fit: BoxFit.cover,
    //           ),
    //         ),
    //       ),
    //       child,
    //     ],
    //   ),
    // );
  }
}

class _LevelPathHeader extends StatelessWidget {
  const _LevelPathHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_ios_new, onPressed: onBack),
        context.dynamicWidth(0.23).width,
        Center(
          child: Text(
            tr('block_mode.adventure.title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4c2d18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: const Color(0xFFF9E4C8), size: 20)),
      ),
    );
  }
}

class _TrophyIntro extends StatelessWidget {
  const _TrophyIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.padding.low,
      decoration: BoxDecoration(
        color: const Color(0x4D4a2a13),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFe9c896), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFFE299), size: context.dynamicHeight(0.05)),
    );
  }
}

class _AdventureBoard extends StatelessWidget {
  const _AdventureBoard({required this.grid, required this.unlockedLevel, required this.currentLevel, required this.onLevelTap});

  final List<List<int?>> grid;
  final int unlockedLevel;
  final int currentLevel;
  final ValueChanged<int> onLevelTap;

  static const double _spacing = 1;

  @override
  Widget build(BuildContext context) {
    final rows = grid.length;
    final columns = LevelPathView._columns;
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth;
        final cellSize = (effectiveWidth - (columns - 1) * _spacing) / columns;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row < rows; row++) ...[
              if (row > 0) const SizedBox(height: _spacing),
              SizedBox(
                width: effectiveWidth,
                child: Row(
                  children: [
                    for (int col = 0; col < columns; col++) ...[
                      if (col > 0) const SizedBox(width: _spacing),
                      _LevelTile(level: grid[row][col], size: cellSize, unlockedLevel: unlockedLevel, currentLevel: currentLevel, onLevelTap: onLevelTap),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.size, required this.unlockedLevel, required this.currentLevel, required this.onLevelTap});

  final int? level;
  final double size;
  final int unlockedLevel;
  final int currentLevel;
  final ValueChanged<int> onLevelTap;

  @override
  Widget build(BuildContext context) {
    if (level == null) {
      return SizedBox(width: size, height: size);
    }

    final unlocked = level! <= unlockedLevel;
    final completed = level! < unlockedLevel;
    final current = level == currentLevel;
    final double badgePadding = size * 0.12;
    final double levelFontSize = size * 0.4;
    final double bottomIconSize = size * 0.22;
    final double spacing = size * 0.08;

    final Gradient gradient = current
        ? const LinearGradient(colors: [Color(0xFFFFE29A), Color(0xFFF0B14C)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : completed
        ? const LinearGradient(colors: [Color(0xFFE7C07C), Color(0xFFB87333)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : unlocked
        ? const LinearGradient(colors: [Color(0xFFD7BA8B), Color(0xFFB08255)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : const LinearGradient(colors: [Color(0xFF352115), Color(0xFF1f130d)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

    final Color borderColor = current
        ? const Color(0xFFFFF3C2)
        : completed
        ? const Color(0xFFf4cf91)
        : unlocked
        ? const Color(0xFFf0d7b4)
        : const Color(0xFF21130c);

    final List<BoxShadow> boxShadow = current
        ? [const BoxShadow(color: Color(0x80FFE29A), blurRadius: 18, offset: Offset(0, 10)), const BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))]
        : [const BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 6))];

    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900, color: unlocked ? const Color(0xFF3b1f0c) : const Color(0xFF79624d), fontSize: levelFontSize.clamp(10, 28), height: 1);

    return GestureDetector(
      onTap: unlocked ? () => onLevelTap(level!) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: boxShadow,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: badgePadding.clamp(6, 18), horizontal: (size * 0.05).clamp(2, 10)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$level', style: textStyle),
                SizedBox(height: spacing.clamp(2, 10)),
                if (!unlocked)
                  Icon(Icons.lock, size: bottomIconSize.clamp(8, 18), color: const Color(0xFF7f6a52))
                else
                  Icon(Icons.circle, size: (bottomIconSize * 0.7).clamp(4, 12), color: const Color(0xFFa85c18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.highestLevel, required this.onJump});

  final int highestLevel;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.dynamicHeight(0.1),
      width: double.infinity,
      padding: context.padding.normal,
      decoration: BoxDecoration(borderRadius: context.border.normalBorderRadius),
      child: ElevatedButton.icon(
        onPressed: onJump,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF52b435),
          foregroundColor: Colors.white,
          padding: context.padding.low,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 8,
          shadowColor: Colors.black45,
        ),
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        label: Text(
          tr('common.level_with_number', namedArgs: {'level': '$highestLevel'}),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
