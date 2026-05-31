import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class OpenAIProvider extends AiProvider {
  /// Override for API proxy/relay services.
  /// Set before making API calls; affects all OpenAIProvider instances.
  static String configuredBaseUrl = 'https://api.openai.com/v1';

  @override
  String get providerName => 'OpenAI';

  @override
  String get baseUrl => configuredBaseUrl;

  @override
  String defaultModel(ModelType type) {
    switch (type) {
      case ModelType.chat:
        return 'gpt-4o';
      case ModelType.code:
        return 'gpt-4o';
      case ModelType.image:
      case ModelType.music:
        return '';
    }
  }

  Dio _createDio(String apiKey) => Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ));

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
          final delta =
              json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (_) {}
      }

      if (lines.isNotEmpty) buffer.write(lines.last);
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty && remaining.startsWith('data: ')) {
      final data = remaining.substring(6);
      if (data != '[DONE]') {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta =
              json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (_) {}
      }
    }
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);
    final response = await dio.post(
      '/images/generations',
      data: {
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': size,
        'quality': 'standard',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final images = data['data'] as List?;
    if (images != null && images.isNotEmpty) {
      return (images[0] as Map<String, dynamic>)['url'] as String?;
    }
    return null;
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      final response = await dio.get('/models');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
