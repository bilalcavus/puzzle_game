import 'dart:math';

final _random = Random();

List<int> generateSolvableSequence(int size) {
  final total = size * size;
  final solved = List<int>.generate(total, (index) => (index + 1) % total);
  var candidate = List<int>.from(solved);

  do {
    candidate.shuffle(_random);
  } while (!_isSolvable(candidate, size) || _isSame(candidate, solved));

  return candidate;
}

bool _isSolvable(List<int> tiles, int size) {
  final inversions = _countInversions(tiles);
  if (size.isOdd) {
    return inversions.isEven;
  }
  final blankIndex = tiles.indexOf(0);
  final blankRowFromBottom = size - (blankIndex ~/ size);
  final isBlankRowEven = blankRowFromBottom.isEven;
  return (isBlankRowEven && inversions.isOdd) || (!isBlankRowEven && inversions.isEven);
}

int _countInversions(List<int> tiles) {
  final filtered = tiles.where((value) => value != 0).toList();
  var inversions = 0;
  for (var i = 0; i < filtered.length - 1; i++) {
    for (var j = i + 1; j < filtered.length; j++) {
      if (filtered[i] > filtered[j]) {
        inversions++;
      }
    }
  }
  return inversions;
}

bool _isSame(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
