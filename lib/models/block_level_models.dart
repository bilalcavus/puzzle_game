import 'package:flutter/material.dart';

import '../core/theme/block_palette.dart';

enum BlockLevelToken { leaf, wood, mushroom, pine }

extension BlockLevelTokenVisuals on BlockLevelToken {
  String get asset {
    switch (this) {
      case BlockLevelToken.leaf:
        return 'assets/images/block_leaf.png';
      case BlockLevelToken.wood:
        return 'assets/images/block_wood.png';
      case BlockLevelToken.mushroom:
        return 'assets/images/mushroom.png';
      case BlockLevelToken.pine:
        return 'assets/images/pine.png';
    }
  }

  Color get color {
    switch (this) {
      case BlockLevelToken.leaf:
        return kClassicBlockPalette[2];
      case BlockLevelToken.wood:
        return kClassicBlockPalette[0];
      case BlockLevelToken.mushroom:
        return kClassicBlockPalette[1];
      case BlockLevelToken.pine:
        return kClassicBlockPalette[3];
    }
  }

  String get label {
    switch (this) {
      case BlockLevelToken.leaf:
        return 'Leaf';
      case BlockLevelToken.wood:
        return 'Log';
      case BlockLevelToken.mushroom:
        return 'Mushroom';
      case BlockLevelToken.pine:
        return 'Pine';
    }
  }
}

class BlockLevelGoal {
  const BlockLevelGoal({required this.token, required this.required, required this.remaining});

  final BlockLevelToken token;
  final int required;
  final int remaining;

  bool get isComplete => remaining <= 0;

  BlockLevelGoal copyWith({int? remaining}) {
    return BlockLevelGoal(token: token, required: required, remaining: remaining ?? this.remaining);
  }

  BlockLevelGoal decrement(int count) {
    if (isComplete || count <= 0) return this;
    final next = (remaining - count).clamp(0, required);
    return copyWith(remaining: next);
  }
}
