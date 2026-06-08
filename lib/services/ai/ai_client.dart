import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'model_router.dart';

class AiClient {
  final Dio _dio;

  AiClient({String? apiKey})
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.deepseek.com/v1',
          headers: {
            if (apiKey != null && ModelRouter.bearerHeader(apiKey) != null)
              'Authorization': ModelRouter.bearerHeader(apiKey)!,
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

  Future<Map<String, dynamic>> chat({
    required List<Map<String, String>> messages,
    String model = 'deepseek-chat',
    double temperature = 0.7,
    int maxTokens = 4096,
    String? apiKey,
  }) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': false,
      },
      options: Options(
        headers: {
          if (apiKey != null && ModelRouter.bearerHeader(apiKey) != null)
            'Authorization': ModelRouter.bearerHeader(apiKey)!,
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  /// SSE streaming chat. Yields content delta strings as they arrive.
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    String model = 'deepseek-chat',
    double temperature = 0.7,
    int maxTokens = 4096,
    String? apiKey,
  }) async* {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      },
      options: Options(
        headers: {
          if (apiKey != null && ModelRouter.bearerHeader(apiKey) != null)
            'Authorization': ModelRouter.bearerHeader(apiKey)!,
        },
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
      final lines = buffer.toString().split('\n');
      buffer.clear();

      // The last element may be incomplete — keep it in buffer
      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        final data = line.substring(6);
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) {
            yield delta;
          }
        } catch (_) {
          // Skip malformed JSON lines
        }
      }

      // Keep incomplete line for next chunk
      if (lines.isNotEmpty) {
        buffer.write(lines.last);
      }
    }

    // Process any remaining data in buffer
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty && remaining.startsWith('data: ')) {
      final data = remaining.substring(6);
      if (data != '[DONE]') {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) {
            yield delta;
          }
        } catch (_) {}
      }
    }
  }
}
