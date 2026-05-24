import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioBridge {
  static final AudioBridge _instance = AudioBridge._();
  factory AudioBridge() => _instance;
  AudioBridge._();

  final _player = AudioPlayer();
  final Map<String, AudioPlayer> _loops = {};

  Future<void> play(String url, {double volume = 1.0, bool loop = false}) async {
    if (loop) {
      final player = AudioPlayer();
      _loops[url] = player;
      await player.setSourceUrl(url);
      await player.setVolume(volume);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.resume();
    } else {
      await _player.stop();
      await _player.setSourceUrl(url);
      await _player.setVolume(volume);
      await _player.resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    for (final p in _loops.values) {
      await p.stop();
      await p.dispose();
    }
    _loops.clear();
  }

  Future<void> stopLoop(String url) async {
    final player = _loops.remove(url);
    if (player != null) {
      await player.stop();
      await player.dispose();
    }
  }

  Future<void> playTone(double frequency, double duration) async {
    // Haptic feedback as a lightweight alternative
    await HapticFeedback.lightImpact();
    await _player.stop();
    // Play a simple tone using a generated source when available,
    // otherwise just use haptic as feedback for game events.
  }

  void dispose() {
    _player.dispose();
    for (final p in _loops.values) {
      p.dispose();
    }
    _loops.clear();
  }
}
