import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundControllerProvider = Provider<SoundController>((ref) {
  final controller = SoundController();
  ref.onDispose(controller.dispose);
  return controller;
});

final soundSettingsProvider = StateNotifierProvider<SoundSettingsNotifier, SoundSettings>((ref) {
  final controller = ref.read(soundControllerProvider);
  return SoundSettingsNotifier(ref, controller);
});

class SoundSettings {
  const SoundSettings({this.musicEnabled = true, this.effectsEnabled = true});

  final bool musicEnabled;
  final bool effectsEnabled;

  SoundSettings copyWith({bool? musicEnabled, bool? effectsEnabled}) {
    return SoundSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
    );
  }
}

class SoundSettingsNotifier extends StateNotifier<SoundSettings> {
  SoundSettingsNotifier(this._ref, this._controller) : super(const SoundSettings()) {
    unawaited(_controller.setMusicEnabled(state.musicEnabled));
    _controller.setEffectsEnabled(state.effectsEnabled);
  }

  final Ref _ref;
  final SoundController _controller;

  void setMusicEnabled(bool enabled) {
    if (state.musicEnabled == enabled) return;
    state = state.copyWith(musicEnabled: enabled);
    unawaited(_controller.setMusicEnabled(enabled));
  }

  void setEffectsEnabled(bool enabled) {
    if (state.effectsEnabled == enabled) return;
    state = state.copyWith(effectsEnabled: enabled);
    _controller.setEffectsEnabled(enabled);
  }
}

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
  bool _effectsEnabled = true;
  bool _musicEnabled = true;

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
    await _playAsset(_comboPlayer, 'audio/combo1.wav');
  }

  Future<void> playFailure() async {
    await _playAsset(_failPlayer, 'audio/failure.wav');
  }

  Future<void> setEffectsEnabled(bool enabled) async {
    _effectsEnabled = enabled;
    if (!enabled) {
      await Future.wait([
        _slidePlayer.stop(),
        _blockPlayer.stop(),
        _successPlayer.stop(),
        _comboPlayer.stop(),
        _failPlayer.stop(),
      ]);
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (enabled) {
      await _ensureBackgroundLoop();
    } else {
      await _backgroundPlayer.stop();
      _backgroundStarted = false;
    }
  }

  Future<void> _ensureBackgroundLoop() async {
    if (_backgroundStarted || !_musicEnabled) return;
    _backgroundStarted = true;
    try {
      await _backgroundPlayer.setVolume(0.25);
      await _backgroundPlayer.play(AssetSource('audio/background_sound.wav'));
    } catch (_) {
      _backgroundStarted = false;
    }
  }

  Future<void> _playAsset(AudioPlayer player, String asset) async {
    if (!_effectsEnabled) return;
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
