import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../model_router.dart';
import 'ai_provider.dart';

class MiniMaxProvider extends AiProvider {
  @override
  String get providerName => 'MiniMax';

  @override
  String get baseUrl => 'https://api.minimaxi.com/v1';

  @override
  String defaultModel(ModelType type) {
    switch (type) {
      case ModelType.chat:
      case ModelType.code:
        return 'MiniMax-M3';
      case ModelType.music:
        return 'music-2.6-free';
      case ModelType.image:
        return '';
    }
  }

  Dio _createDio(String apiKey) {
    final authHeader = ModelRouter.bearerHeader(apiKey);
    if (authHeader == null) {
      throw const FormatException('Invalid MiniMax API key format.');
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 300),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final dio = _createDio(apiKey);
    final response = await dio.post(
      '/chat/completions',
      data: {
        'model': model ?? defaultModel(ModelType.chat),
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': false,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    final dio = _createDio(apiKey);
    final response = await dio.post(
      '/chat/completions',
      data: {
        'model': model ?? defaultModel(ModelType.chat),
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      },
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data.stream as Stream<List<int>>;
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
      final lines = buffer.toString().split('\n');
      buffer.clear();

      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        final data = line.substring(6);
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (_) {}
      }

      if (lines.isNotEmpty) buffer.write(lines.last);
    }

    final remaining = buffer.toString().trim();
    if (remaining.startsWith('data: ')) {
      final data = remaining.substring(6);
      if (data != '[DONE]') {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (_) {}
      }
    }
  }

  @override
  Future<String?> generateMusic({
    required String prompt,
    required String apiKey,
    String? lyrics,
    bool instrumental = true,
    String format = 'mp3',
  }) async {
    final cleanedPrompt = prompt.trim();
    if (cleanedPrompt.isEmpty) {
      throw ArgumentError('MiniMax music prompt cannot be empty');
    }

    final normalizedFormat = switch (format.toLowerCase()) {
      'wav' => 'wav',
      'pcm' => 'pcm',
      _ => 'mp3',
    };
    final cleanedLyrics = lyrics?.trim();

    final body = <String, dynamic>{
      'model': defaultModel(ModelType.music),
      'prompt': cleanedPrompt,
      'stream': false,
      'output_format': 'url',
      'aigc_watermark': false,
      'is_instrumental': instrumental,
      'audio_setting': {
        'sample_rate': 44100,
        'bitrate': 256000,
        'format': normalizedFormat,
      },
    };

    if (!instrumental) {
      if (cleanedLyrics != null && cleanedLyrics.isNotEmpty) {
        body['lyrics'] = cleanedLyrics;
      } else {
        body['lyrics_optimizer'] = true;
      }
    }

    final dio = _createDio(apiKey);
    final response = await dio.post('/music_generation', data: body);
    final data = response.data as Map<String, dynamic>;
    final baseResp = data['base_resp'] as Map<String, dynamic>?;
    final statusCode = baseResp?['status_code'] as int?;

    if (statusCode != null && statusCode != 0) {
      final message = baseResp?['status_msg'] as String? ?? 'unknown error';
      throw Exception('MiniMax music generation failed: $message');
    }

    final musicData = data['data'] as Map<String, dynamic>?;
    final audio = musicData?['audio'] as String?;
    if (audio == null || audio.isEmpty) return null;

    if (audio.startsWith('http://') ||
        audio.startsWith('https://') ||
        audio.startsWith('data:')) {
      return audio;
    }

    return _hexAudioToDataUrl(audio, normalizedFormat);
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      final response = await dio.get('/models');
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) return false;
      }
      return false;
    }
  }

  @override
  Future<bool> testConnectionForModel(String apiKey, ModelType type) {
    // Music generation itself can be slow and may spend quota, so the settings
    // page only validates the API host/key through the lightweight models call.
    return testConnection(apiKey);
  }

  String _hexAudioToDataUrl(String hex, String format) {
    final normalized = hex.replaceAll(RegExp(r'\s+'), '');
    if (normalized.length.isOdd) {
      throw const FormatException('Invalid MiniMax hex audio payload');
    }

    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }

    final mime = format == 'wav'
        ? 'audio/wav'
        : format == 'pcm'
        ? 'audio/L16'
        : 'audio/mpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}
