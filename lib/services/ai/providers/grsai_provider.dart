import 'dart:async';

import 'package:dio/dio.dart';

import '../model_router.dart';
import 'ai_provider.dart';

class GrsaiProvider extends AiProvider {
  static const _pollInterval = Duration(seconds: 3);
  static const _maxWait = Duration(seconds: 300);

  @override
  String get providerName => 'GRS AI';

  @override
  String get baseUrl => 'https://grsai.dakka.com.cn';

  @override
  String defaultModel(ModelType type) {
    switch (type) {
      case ModelType.image:
        return 'gpt-image-2';
      case ModelType.chat:
      case ModelType.code:
      case ModelType.music:
        return '';
    }
  }

  Dio _createDio(String apiKey) {
    final authHeader = ModelRouter.bearerHeader(apiKey);
    if (authHeader == null) {
      throw const FormatException('Invalid GRS AI API key format.');
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: _maxWait,
        sendTimeout: const Duration(seconds: 45),
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
  }) {
    throw UnsupportedError('GRS AI is configured for image generation only.');
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) {
    throw UnsupportedError('GRS AI is configured for image generation only.');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);
    final taskId = await _createImageTask(dio, prompt, size);
    final result = await _pollImageResult(dio, taskId);
    return _extractResultUrl(result);
  }

  Future<String> _createImageTask(Dio dio, String prompt, String size) async {
    final response = await dio.post(
      '/v1/draw/completions',
      data: {
        'model': defaultModel(ModelType.image),
        'prompt': _gameAssetPrompt(prompt),
        'aspectRatio': size,
        'quality': 'high',
        'webHook': '-1',
        'shutProgress': false,
      },
    );

    final data = _asMap(response.data);
    final code = data['code'];
    if (code != null && code != 0) {
      throw Exception(data['msg'] ?? 'GRS AI image task creation failed');
    }

    final taskData = _asMap(data['data']);
    final id = taskData['id']?.toString();
    if (id == null || id.isEmpty) {
      final directUrl = _extractResultUrl(data);
      if (directUrl != null) return directUrl;
      throw Exception('GRS AI did not return an image task id');
    }
    return id;
  }

  Future<Map<String, dynamic>> _pollImageResult(Dio dio, String taskId) async {
    if (taskId.startsWith('http://') || taskId.startsWith('https://')) {
      return {
        'status': 'succeeded',
        'results': [
          {'url': taskId},
        ],
      };
    }

    final deadline = DateTime.now().add(_maxWait);
    Map<String, dynamic>? latest;

    while (DateTime.now().isBefore(deadline)) {
      final response = await dio.post('/v1/draw/result', data: {'id': taskId});
      final data = _asMap(response.data);
      final code = data['code'];
      if (code != null && code != 0) {
        throw Exception(data['msg'] ?? 'GRS AI result query failed');
      }

      latest = _asMap(data['data']);
      final status = latest['status']?.toString();
      if (status == 'succeeded') return latest;
      if (status == 'failed') {
        final reason = latest['failure_reason'] ?? 'unknown';
        final detail = latest['error'] ?? '';
        throw Exception('GRS AI image generation failed: $reason $detail');
      }

      await Future.delayed(_pollInterval);
    }

    final progress = latest?['progress'];
    throw TimeoutException(
      'GRS AI image generation did not finish within ${_maxWait.inSeconds}s'
      '${progress == null ? '' : ' (progress: $progress%)'}',
      _maxWait,
    );
  }

  String? _extractResultUrl(Map<String, dynamic> data) {
    final legacyUrl = data['url']?.toString();
    if (legacyUrl != null && legacyUrl.isNotEmpty) return legacyUrl;

    final results = data['results'];
    if (results is List && results.isNotEmpty) {
      final first = results.first;
      if (first is Map) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  String _gameAssetPrompt(String prompt) {
    return '''
$prompt

Create a game-ready 2D asset/sprite with transparent background. The subject must be isolated, centered, fully visible, and not placed in a scene. No background, no floor, no shadow, no text, no watermark, no frame. Use clean edges suitable for direct use in a canvas game. If transparency is supported, output PNG with alpha channel.
''';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    return apiKey.trim().isNotEmpty;
  }

  @override
  Future<bool> testConnectionForModel(String apiKey, ModelType type) {
    return testConnection(apiKey);
  }
}
