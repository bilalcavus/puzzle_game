import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundControllerProvider = Provider<SoundController>((ref) {
  final controller = SoundController();
  ref.onDispose(controller.dispose);
  return controller;
});

class SoundController {
  SoundController() {
    for (final player in [_slidePlayer, _blockPlayer, _successPlayer, _comboPlayer, _failPlayer]) {
      player.setReleaseMode(ReleaseMode.stop);
    }
    _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    unawaited(_ensureBackgroundLoop());
  }

  final AudioPlayer _slidePlayer = AudioPlayer();
  final AudioPlayer _blockPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _comboPlayer = AudioPlayer();
  final AudioPlayer _failPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _backgroundStarted = false;

  Future<void> playMove() async {
    await _playAsset(_slidePlayer, 'audio/move.wav');
  }

  Future<void> playBlockPlace() async {
    await _playAsset(_blockPlayer, 'audio/block_place.wav');
  }

  Future<void> playSuccess() async {
    await _playAsset(_successPlayer, 'audio/success.wav');
  }

  Future<void> playCombo() async {
    await _playAsset(_comboPlayer, 'audio/combo.wav');
  }

  Future<void> playFailure() async {
    await _playAsset(_failPlayer, 'audio/failure.wav');
  }

  Future<void> _ensureBackgroundLoop() async {
    if (_backgroundStarted) return;
    _backgroundStarted = true;
    try {
      await _backgroundPlayer.setVolume(0.25);
      await _backgroundPlayer.play(AssetSource('audio/background_sound.wav'));
    } catch (_) {
      _backgroundStarted = false;
    }
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
    _comboPlayer.dispose();
    _failPlayer.dispose();
    _backgroundPlayer.dispose();
  }
}
