import 'dart:convert';

class BlockLeaderboardEntry {
  const BlockLeaderboardEntry({
    required this.name,
    required this.score,
    required this.linesCleared,
    required this.completedAt,
  });

  final String name;
  final int score;
  final int linesCleared;
  final DateTime completedAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
      'linesCleared': linesCleared,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BlockLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return BlockLeaderboardEntry(
      name: map['name'] as String? ?? 'WoodMaster',
      score: map['score'] as int? ?? 0,
      linesCleared: map['linesCleared'] as int? ?? 0,
      completedAt: DateTime.tryParse(map['completedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory BlockLeaderboardEntry.fromJson(String source) {
    return BlockLeaderboardEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
