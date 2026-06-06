import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioBridge {
  static final AudioBridge _instance = AudioBridge._();
  factory AudioBridge() => _instance;
  AudioBridge._();

  final _player = AudioPlayer();
  final Map<String, AudioPlayer> _loops = {};

  Future<void> play(
    String url, {
    double volume = 1.0,
    bool loop = false,
  }) async {
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
    await _safeStop(_player);
    final loopPlayers = List<AudioPlayer>.from(_loops.values);
    _loops.clear();
    for (final p in loopPlayers) {
      await _safeStop(p);
      await _safeDispose(p);
    }
  }

  Future<void> stopLoop(String url) async {
    final player = _loops.remove(url);
    if (player != null) {
      await _safeStop(player);
      await _safeDispose(player);
    }
  }

  Future<void> playTone(double frequency, double duration) async {
    // Haptic feedback as a lightweight alternative
    await HapticFeedback.lightImpact();
    await _safeStop(_player);
    // Play a simple tone using a generated source when available,
    // otherwise just use haptic as feedback for game events.
  }

  void dispose() {
    final loopPlayers = List<AudioPlayer>.from(_loops.values);
    _loops.clear();
    for (final p in loopPlayers) {
      _safeDispose(p);
    }
    _safeStop(_player);
  }

  Future<void> _safeStop(AudioPlayer player) async {
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> _safeDispose(AudioPlayer player) async {
    try {
      await player.dispose();
    } catch (_) {}
  }
}
