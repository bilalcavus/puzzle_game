import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundControllerProvider = Provider<SoundController>((ref) {
  final controller = SoundController();
  ref.onDispose(controller.dispose);
  return controller;
});

class SoundController {
  SoundController() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> playMove() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/move.wav'));
    } catch (_) {
      // Silently ignore audio errors so the puzzle keeps running smoothly.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
