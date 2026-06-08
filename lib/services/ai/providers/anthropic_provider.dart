import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class AnthropicProvider extends AiProvider {
  @override
  String get providerName => 'Anthropic';

  @override
  String get baseUrl => 'https://api.anthropic.com/v1';

  @override
  String defaultModel(ModelType type) {
    switch (type) {
      case ModelType.chat:
        return 'claude-sonnet-4-20250514';
      case ModelType.code:
        return 'claude-opus-4-20250514';
      case ModelType.music:
        return 'claude-sonnet-4-20250514';
      case ModelType.image:
        return '';
    }
  }

  Dio _createDio(String apiKey) {
    final sanitizedKey = ModelRouter.sanitizeApiKey(apiKey);
    if (!ModelRouter.isValidApiKey(sanitizedKey)) {
      throw const FormatException('Invalid Anthropic API key format.');
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-api-key': sanitizedKey,
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
  }

  /// Separates system message from the messages list for Anthropic's API format.
  Map<String, dynamic> _buildRequestBody({
    required List<Map<String, String>> messages,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) {
    String? systemPrompt;
    final chatMessages = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemPrompt = msg['content'];
      } else {
        chatMessages.add({'role': msg['role'], 'content': msg['content']});
      }
    }

    final body = <String, dynamic>{
      'model': model ?? defaultModel(ModelType.chat),
      'max_tokens': maxTokens,
      'messages': chatMessages,
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    // Anthropic doesn't support temperature + top_p together well;
    // just pass temperature.
    body['temperature'] = temperature;

    return body;
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
    final body = _buildRequestBody(
      messages: messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final response = await dio.post('/messages', data: body);

    // Normalize Anthropic response to OpenAI-compatible format
    final data = response.data as Map<String, dynamic>;
    final contentList = data['content'] as List?;
    String text = '';
    if (contentList != null) {
      for (final block in contentList) {
        if (block is Map<String, dynamic> && block['type'] == 'text') {
          text += block['text'] as String? ?? '';
        }
      }
    }

    return {
      'choices': [
        {
          'message': {'content': text},
        },
      ],
    };
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
    final body = _buildRequestBody(
      messages: messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    body['stream'] = true;

    final response = await dio.post(
      '/messages',
      data: body,
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
          final eventType = json['type'] as String?;

          if (eventType == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            final text = delta?['text'] as String?;
            if (text != null && text.isNotEmpty) yield text;
          }
        } catch (_) {}
      }

      if (lines.isNotEmpty) buffer.write(lines.last);
    }
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      // Anthropic doesn't have a models list endpoint; send a minimal message
      final body = {
        'model': defaultModel(ModelType.chat),
        'max_tokens': 1,
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
      };
      final response = await dio.post('/messages', data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
