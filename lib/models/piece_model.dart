import 'dart:convert';

import 'package:flutter/material.dart';

import 'block_model.dart';
import 'block_level_models.dart';

class PieceModel {
  const PieceModel({
    required this.id,
    required this.blocks,
    required this.color,
    this.tokenBlocks = const <int, BlockLevelToken>{},
  });

  final String id;
  final List<BlockModel> blocks;
  final Color color;
  final Map<int, BlockLevelToken> tokenBlocks;

  int get width => blocks.map((b) => b.colOffset).reduce((a, b) => a > b ? a : b) + 1;
  int get height => blocks.map((b) => b.rowOffset).reduce((a, b) => a > b ? a : b) + 1;
  int get cellCount => blocks.length;
  BlockLevelToken? tokenForBlockIndex(int index) => tokenBlocks[index];

  PieceModel copyWith({List<BlockModel>? blocks, Color? color, Map<int, BlockLevelToken>? tokenBlocks}) {
    return PieceModel(
      id: id,
      blocks: blocks ?? this.blocks,
      color: color ?? this.color,
      tokenBlocks: tokenBlocks ?? this.tokenBlocks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color.toARGB32(),
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'tokens': tokenBlocks.map((key, value) => MapEntry(key.toString(), value.name)),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory PieceModel.fromMap(Map<String, dynamic> map) {
    final rawTokens = map['tokens'] as Map?;
    final tokens = <int, BlockLevelToken>{};
    if (rawTokens != null) {
      rawTokens.forEach((key, value) {
        final index = int.tryParse(key.toString());
        if (index != null) {
          final name = value?.toString();
          if (name != null) {
            final token = BlockLevelToken.values.firstWhere(
              (entry) => entry.name == name,
              orElse: () => BlockLevelToken.leaf,
            );
            tokens[index] = token;
          }
        }
      });
    }
    return PieceModel(
      id: map['id'] as String,
      color: Color(map['color'] as int),
      blocks: (map['blocks'] as List<dynamic>).map((e) => BlockModel.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      tokenBlocks: tokens,
    );
  }

  factory PieceModel.fromJson(String source) => PieceModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
