// ignore_for_file: unused_field

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundControllerProvider = Provider<SoundController>((ref) {
  final controller = SoundController();
  ref.onDispose(controller.dispose);
  return controller;
});

final soundSettingsProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettings>((ref) {
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
  SoundSettingsNotifier(this._ref, this._controller)
    : super(const SoundSettings()) {
    _controller.setEffectsEnabled(state.effectsEnabled);
  }

  final Ref _ref;
  final SoundController _controller;

  void setMusicEnabled(bool enabled) {
    if (state.musicEnabled == enabled) return;
    state = state.copyWith(musicEnabled: enabled);
  }

  void setEffectsEnabled(bool enabled) {
    if (state.effectsEnabled == enabled) return;
    state = state.copyWith(effectsEnabled: enabled);
    _controller.setEffectsEnabled(enabled);
  }
}

class SoundController with WidgetsBindingObserver {
  SoundController() {
    for (final player in [
      _slidePlayer,
      _blockPlayer,
      _successPlayer,
      _comboPlayer,
      _failPlayer,
      _perfectPlayer,
      _levelPlayer,
      _dragPlayer,
    ]) {
      player.setReleaseMode(ReleaseMode.stop);
    }
    _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioPlayer _slidePlayer = AudioPlayer();
  final AudioPlayer _blockPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _perfectPlayer = AudioPlayer();
  final AudioPlayer _comboPlayer = AudioPlayer();
  final AudioPlayer _levelPlayer = AudioPlayer();
  final AudioPlayer _failPlayer = AudioPlayer();
  final AudioPlayer _dragPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _effectsEnabled = true;

  Future<void> playMove() async {
    await _playAsset(_slidePlayer, 'audio/move.wav');
  }

  Future<void> playDrag() async {
    await _playAsset(_dragPlayer, 'audio/drag_sound.wav');
  }

  Future<void> playBlockPlace() async {
    await _playAsset(_blockPlayer, 'audio/block_place.wav');
  }

  Future<void> playSuccess() async {
    await _playAsset(_successPlayer, 'audio/success_bell-6776.mp3');
  }

  Future<void> playPerfect() async {
    await _playAsset(_perfectPlayer, 'audio/perfect.wav');
  }

  Future<void> playCombo() async {
    await _playAsset(_comboPlayer, 'audio/combo1.wav');
  }

  Future<void> playLevelUp() async {
    await _playAsset(_levelPlayer, 'audio/level_sound.mp3');
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
        _levelPlayer.stop(),
        _failPlayer.stop(),
        _perfectPlayer.stop(),
        _dragPlayer.stop(),
      ]);
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
    WidgetsBinding.instance.removeObserver(this);
    _slidePlayer.dispose();
    _blockPlayer.dispose();
    _successPlayer.dispose();
    _comboPlayer.dispose();
    _levelPlayer.dispose();
    _failPlayer.dispose();
    _perfectPlayer.dispose();
    _dragPlayer.dispose();
    _backgroundPlayer.dispose();
  }
}
