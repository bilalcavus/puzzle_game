import 'package:flutter/material.dart';

enum BlockLevelToken { leaf, wood, axe }

extension BlockLevelTokenVisuals on BlockLevelToken {
  String get asset {
    switch (this) {
      case BlockLevelToken.leaf:
        return 'assets/images/block_leaf.png';
      case BlockLevelToken.wood:
        return 'assets/images/block_wood.png';
      case BlockLevelToken.axe:
        return 'assets/images/block_axe.png';
    }
  }

  Color get color {
    switch (this) {
      case BlockLevelToken.leaf:
        return const Color(0xFF6BD18A);
      case BlockLevelToken.wood:
        return const Color(0xFFC47A47);
      case BlockLevelToken.axe:
        return const Color(0xFFFFC857);
    }
  }

  String get label {
    switch (this) {
      case BlockLevelToken.leaf:
        return 'Leaf';
      case BlockLevelToken.wood:
        return 'Log';
      case BlockLevelToken.axe:
        return 'Axe';
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
