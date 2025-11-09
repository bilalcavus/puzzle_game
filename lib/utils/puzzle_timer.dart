import 'dart:async';

class PuzzleTimerHelper {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  void start(void Function(Duration elapsed) onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      onTick(_elapsed);
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void reset() {
    stop();
    _elapsed = Duration.zero;
  }

  void dispose() {
    _timer?.cancel();
  }
}
