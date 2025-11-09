import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundControllerProvider = Provider<SoundController>((ref) {
  final controller = SoundController();
  ref.onDispose(controller.dispose);
  return controller;
});

class SoundController {
  SoundController() {
    for (final player in [_slidePlayer, _blockPlayer, _successPlayer]) {
      player.setReleaseMode(ReleaseMode.stop);
    }
  }

  final AudioPlayer _slidePlayer = AudioPlayer();
  final AudioPlayer _blockPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();

  Future<void> playMove() async {
    await _playAsset(_slidePlayer, 'audio/move.wav');
  }

  Future<void> playBlockPlace() async {
    await _playAsset(_blockPlayer, 'audio/block_place.wav');
  }

  Future<void> playSuccess() async {
    await _playAsset(_successPlayer, 'audio/success.wav');
  }

  Future<void> _playAsset(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Ignore audio errors to keep gameplay smooth.
    }
  }

  void dispose() {
    _slidePlayer.dispose();
    _blockPlayer.dispose();
    _successPlayer.dispose();
  }
}
