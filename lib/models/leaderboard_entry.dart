import 'dart:convert';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.moves,
    required this.duration,
    required this.completedAt,
  });

  final String name;
  final int moves;
  final Duration duration;
  final DateTime completedAt;

  LeaderboardEntry copyWith({String? name}) {
    return LeaderboardEntry(
      name: name ?? this.name,
      moves: moves,
      duration: duration,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'moves': moves,
      'duration': duration.inSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      name: map['name'] as String? ?? 'Player',
      moves: map['moves'] as int? ?? 0,
      duration: Duration(seconds: map['duration'] as int? ?? 0),
      completedAt: DateTime.tryParse(map['completedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory LeaderboardEntry.fromJson(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return LeaderboardEntry.fromMap(decoded);
  }
}
