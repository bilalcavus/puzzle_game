import 'package:flutter/material.dart';

class CellModel {
  const CellModel({
    required this.row,
    required this.col,
    this.color,
  });

  final int row;
  final int col;
  final Color? color;

  bool get isFilled => color != null;
}
