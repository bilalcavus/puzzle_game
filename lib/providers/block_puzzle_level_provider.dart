import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'block_puzzle_provider.dart';

final blockPuzzleLevelProvider = StateNotifierProvider<BlockPuzzleNotifier, BlockPuzzleState>(
  (ref) {
    final notifier = BlockPuzzleNotifier(ref, enablePersistence: false);
    notifier.startLevelChallenge(level: 1);
    return notifier;
  },
);
