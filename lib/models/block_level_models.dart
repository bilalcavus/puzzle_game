import 'package:flutter/material.dart';

enum BlockLevelToken { leaf, wood, mushroom }

extension BlockLevelTokenVisuals on BlockLevelToken {
  String get asset {
    switch (this) {
      case BlockLevelToken.leaf:
        return 'assets/images/block_leaf.png';
      case BlockLevelToken.wood:
        return 'assets/images/block_wood.png';
      case BlockLevelToken.mushroom:
        return 'assets/images/mushroom.png';
    }
  }

  Color get color {
    switch (this) {
      case BlockLevelToken.leaf:
        return const Color.fromARGB(255, 109, 41, 8);
      case BlockLevelToken.wood:
        return const Color(0xFFC47A47);
      case BlockLevelToken.mushroom:
        return const Color.fromARGB(255, 255, 170, 24);
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
    }
  }
}

class BlockLevelGoal {
  const BlockLevelGoal({
    required this.token,
    required this.required,
    required this.remaining,
  });

  final BlockLevelToken token;
  final int required;
  final int remaining;

  bool get isComplete => remaining <= 0;

  BlockLevelGoal copyWith({int? remaining}) {
    return BlockLevelGoal(
      token: token,
      required: required,
      remaining: remaining ?? this.remaining,
    );
  }

  BlockLevelGoal decrement(int count) {
    if (isComplete || count <= 0) return this;
    final next = (remaining - count).clamp(0, required);
    return copyWith(remaining: next);
  }
}
