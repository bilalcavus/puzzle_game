import 'dart:convert';

import 'package:flutter/material.dart';

import 'block_model.dart';

class PieceModel {
  const PieceModel({
    required this.id,
    required this.blocks,
    required this.color,
  });

  final String id;
  final List<BlockModel> blocks;
  final Color color;

  int get width => blocks.map((b) => b.colOffset).reduce((a, b) => a > b ? a : b) + 1;
  int get height => blocks.map((b) => b.rowOffset).reduce((a, b) => a > b ? a : b) + 1;
  int get cellCount => blocks.length;

  PieceModel copyWith({List<BlockModel>? blocks, Color? color}) {
    return PieceModel(
      id: id,
      blocks: blocks ?? this.blocks,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color.toARGB32(),
      'blocks': blocks.map((b) => b.toMap()).toList(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory PieceModel.fromMap(Map<String, dynamic> map) {
    return PieceModel(
      id: map['id'] as String,
      color: Color(map['color'] as int),
      blocks: (map['blocks'] as List<dynamic>).map((e) => BlockModel.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  factory PieceModel.fromJson(String source) => PieceModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
