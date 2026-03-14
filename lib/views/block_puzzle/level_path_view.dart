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

class LevelPathView extends ConsumerStatefulWidget {
  const LevelPathView({super.key});

  static const int _columns = 11;

  @override
  ConsumerState<LevelPathView> createState() => _LevelPathViewState();
}

class _LevelPathViewState extends ConsumerState<LevelPathView> {
  static const List<_RowSpec> _firstPageSpecs = [
    // Canopy (image-like, wide top)
    _RowSpec(count: 1, start: 5),
    _RowSpec(count: 5, start: 3),
    _RowSpec(count: 7, start: 2),
    _RowSpec(count: 9, start: 1),
    _RowSpec(count: 7, start: 2),
    _RowSpec(count: 7, start: 2),
    _RowSpec(count: 5, start: 3),
    // Trunk
    _RowSpec(count: 1, start: 5),
    _RowSpec(count: 1, start: 5),
    _RowSpec(count: 1, start: 5),
    _RowSpec(count: 1, start: 5),
    _RowSpec(count: 1, start: 5),
  ];
  static const List<_RowSpec> _secondPageSpecs = [
    // Mushroom cap
    _RowSpec(count: 2, start: 4),
    _RowSpec(count: 4, start: 3),

    _RowSpec(count: 6, start: 2),
    _RowSpec(count: 8, start: 1),
    _RowSpec(count: 10, start: 0),
    _RowSpec(count: 10, start: 0),
    // Stem
    _RowSpec(count: 2, start: 4),
    _RowSpec(count: 2, start: 4),
    _RowSpec(count: 2, start: 4),

    _RowSpec(count: 2, start: 4),
    _RowSpec(count: 2, start: 4),
  ];
  static final List<List<int?>> _firstPageGrid = _buildLevelGrid(specs: _firstPageSpecs, startLevel: 1);
  static final List<List<int?>> _secondPageGrid = _buildLevelGrid(specs: _secondPageSpecs, startLevel: 47);
  static const int _totalLevels = 96;

  static const int _secondPageStart = 47;

  late Future<int> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<int>(
        future: _progressFuture,
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
          final showSecondPage = unlockedLevel >= _secondPageStart;

          Future<void> handleLevelTap(int level) async {
            ref.read(blockPuzzleLevelProvider.notifier).startLevelChallenge(level: level);
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlockPuzzleLevelGameView()));
            if (!mounted) return;
            setState(() {
              _progressFuture = _loadProgress();
            });
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
                      child: showSecondPage
                          ? _AdventurePage(
                              title: '47-96',
                              grid: _secondPageGrid,
                              unlockedLevel: unlockedLevel,
                              currentLevel: currentLevel,
                              onLevelTap: handleLevelTap,
                              horizontalShiftCols: 0.5,
                            )
                          : _AdventurePage(
                              title: '1-46',
                              grid: _firstPageGrid,
                              unlockedLevel: unlockedLevel,
                              currentLevel: currentLevel,
                              onLevelTap: handleLevelTap,
                            ),
                    ),
                    const SizedBox(height: 8),
                    if (!showSecondPage)
                      Text(
                        '47-96 bolumu, 46. level bitince acilir.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFF5DEB8), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
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

  static List<List<int?>> _buildLevelGrid({required List<_RowSpec> specs, required int startLevel}) {
    final rows = specs.length;
    final grid = List<List<int?>>.generate(rows, (_) => List<int?>.filled(LevelPathView._columns, null));
    int level = startLevel;

    for (int row = rows - 1; row >= 0; row--) {
      final spec = specs[row];
      final startIndex = spec.start.clamp(0, LevelPathView._columns - 1);
      final maxCount = LevelPathView._columns - startIndex;
      final count = spec.count.clamp(0, maxCount);
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

class _AdventurePage extends StatelessWidget {
  const _AdventurePage({
    required this.title,
    required this.grid,
    required this.unlockedLevel,
    required this.currentLevel,
    required this.onLevelTap,
    this.horizontalShiftCols = 0,
  });

  final String title;
  final List<List<int?>> grid;
  final int unlockedLevel;
  final int currentLevel;
  final ValueChanged<int> onLevelTap;
  final double horizontalShiftCols;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFFFBE8C8)),
            ),
            const SizedBox(height: 12),
            _AdventureBoard(
              grid: grid,
              unlockedLevel: unlockedLevel,
              currentLevel: currentLevel,
              onLevelTap: onLevelTap,
              horizontalShiftCols: horizontalShiftCols,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AdventureBoard extends StatelessWidget {
  const _AdventureBoard({
    required this.grid,
    required this.unlockedLevel,
    required this.currentLevel,
    required this.onLevelTap,
    this.horizontalShiftCols = 0,
  });

  final List<List<int?>> grid;
  final int unlockedLevel;
  final int currentLevel;
  final ValueChanged<int> onLevelTap;
  final double horizontalShiftCols;

  static const double _spacing = 1;

  @override
  Widget build(BuildContext context) {
    final rows = grid.length;
    final columns = LevelPathView._columns;
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth;
        final cellSize = (effectiveWidth - (columns - 1) * _spacing) / columns;

        return Transform.translate(
          offset: Offset(cellSize * horizontalShiftCols, 0),
          child: Column(
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
          ),
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
    final double spacing = size * 0.08;

    final bool isStemLevel = level! >= 47 && level! <= 56;
    final bool isCapLevel = level! >= 57 && level! <= 96;
    final bool isTrunkLevel = level! <= 5;
    final Color currentTop = isCapLevel
        ? const Color(0xFFFF8578)
        : isStemLevel
        ? const Color(0xFFE7C89E)
        : isTrunkLevel
        ? const Color(0xFFF1C27D)
        : const Color(0xFF9BE7A1);
    final Color currentBottom = isCapLevel
        ? const Color(0xFFD83E33)
        : isStemLevel
        ? const Color(0xFFB98D57)
        : isTrunkLevel
        ? const Color(0xFFB8782E)
        : const Color(0xFF2F8E48);
    final Color completedTop = isCapLevel
        ? const Color(0xFFF46F63)
        : isStemLevel
        ? const Color(0xFFDFC092)
        : isTrunkLevel
        ? const Color(0xFFE3B56F)
        : const Color(0xFF86D08C);
    final Color completedBottom = isCapLevel
        ? const Color(0xFFC7382F)
        : isStemLevel
        ? const Color(0xFFA87C4B)
        : isTrunkLevel
        ? const Color(0xFF9C6427)
        : const Color(0xFF2D7D40);
    final Color unlockedTop = isCapLevel
        ? const Color(0xFFEB655A)
        : isStemLevel
        ? const Color(0xFFD6B684)
        : isTrunkLevel
        ? const Color(0xFFD4A56A)
        : const Color(0xFF7ECF86);
    final Color unlockedBottom = isCapLevel
        ? const Color(0xFFB73028)
        : isStemLevel
        ? const Color(0xFF936B40)
        : isTrunkLevel
        ? const Color(0xFF8B5A22)
        : const Color(0xFF2B6F3A);
    final Color lockedTop = isCapLevel
        ? const Color(0xFF4A1E1A)
        : isStemLevel
        ? const Color(0xFF3A2A18)
        : isTrunkLevel
        ? const Color(0xFF3B2616)
        : const Color(0xFF20361F);
    final Color lockedBottom = isCapLevel
        ? const Color(0xFF2B110E)
        : isStemLevel
        ? const Color(0xFF241A10)
        : isTrunkLevel
        ? const Color(0xFF24170C)
        : const Color(0xFF142217);

    final Gradient gradient = current
        ? LinearGradient(colors: [currentTop, currentBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : completed
        ? LinearGradient(colors: [completedTop, completedBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : unlocked
        ? LinearGradient(colors: [unlockedTop, unlockedBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : LinearGradient(colors: [lockedTop, lockedBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter);

    final Color borderColor = current
        ? const Color(0xFFFFF3C2)
        : completed
        ? const Color(0xFFf4cf91)
        : unlocked
        ? const Color(0xFFf0d7b4)
        : const Color(0xFF21130c);

    final List<BoxShadow> boxShadow = current
        ? [const BoxShadow(color: Color(0x55FFE29A), blurRadius: 8, offset: Offset(0, 4))]
        : const <BoxShadow>[];

    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900, color: unlocked ? const Color(0xFF3b1f0c) : const Color(0xFF79624d), fontSize: levelFontSize.clamp(10, 28), height: 1);

    return SizedBox.square(
      dimension: size,
      child: GestureDetector(
        onTap: unlocked ? () => onLevelTap(level!) : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: borderColor, width: 1.2),
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
                  if (!unlocked) ...[SizedBox(height: spacing.clamp(2, 10)), Icon(Icons.lock, size: (size * 0.22).clamp(8, 18), color: const Color(0xFF7f6a52))],
                ],
              ),
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

class _RowSpec {
  const _RowSpec({required this.count, required this.start});

  final int count;
  final int start;
}
