class BlockModel {
  const BlockModel({required this.rowOffset, required this.colOffset});

  final int rowOffset;
  final int colOffset;

  BlockModel copyWith({int? rowOffset, int? colOffset}) {
    return BlockModel(
      rowOffset: rowOffset ?? this.rowOffset,
      colOffset: colOffset ?? this.colOffset,
    );
  }

  Map<String, dynamic> toMap() => {'r': rowOffset, 'c': colOffset};

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      rowOffset: map['r'] as int? ?? 0,
      colOffset: map['c'] as int? ?? 0,
    );
  }
}
