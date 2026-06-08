import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class GeminiProvider extends AiProvider {
  @override
  String get providerName => 'Gemini';

  @override
  String get baseUrl => 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String defaultModel(ModelType type) {
    switch (type) {
      case ModelType.image:
        return 'gemini-2.5-flash-image';
      case ModelType.code:
        return 'gemini-2.5-pro';
      case ModelType.chat:
      case ModelType.music:
        return 'gemini-2.5-flash';
    }
  }

  Dio _createDio(String apiKey) {
    final sanitizedKey = ModelRouter.sanitizeApiKey(apiKey);
    if (!ModelRouter.isValidApiKey(sanitizedKey)) {
      throw const FormatException('Invalid Gemini API key format.');
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-goog-api-key': sanitizedKey,
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 240),
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
      '/models/${model ?? defaultModel(ModelType.chat)}:generateContent',
      data: {
        'contents': _toGeminiContents(messages),
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      },
    );
    final text = _extractText(response.data as Map<String, dynamic>);
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
    final response = await dio.post(
      '/models/${model ?? defaultModel(ModelType.chat)}:streamGenerateContent',
      data: {
        'contents': _toGeminiContents(messages),
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      },
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data.stream as Stream<List<int>>;
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
    }

    final raw = buffer.toString().trim();
    if (raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final text = _extractText(item);
            if (text.isNotEmpty) yield text;
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        final text = _extractText(decoded);
        if (text.isNotEmpty) yield text;
      }
    } catch (_) {
      // Some gateways stream JSON fragments. Fall back to one-shot chat.
      final result = await chat(
        messages: messages,
        apiKey: apiKey,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      final text = result['choices']?[0]?['message']?['content'] as String?;
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);

    DioException? lastError;
    for (final imageModel in const [
      'gemini-2.5-flash-image',
      'gemini-2.5-flash-image-preview',
    ]) {
      try {
        final response = await dio.post(
          '/models/$imageModel:generateContent',
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'responseModalities': ['IMAGE', 'TEXT'],
            },
          },
        );

        return _extractInlineImage(response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        if (status != 400 && status != 404) rethrow;
      }
    }

    if (lastError != null) throw lastError;
    return null;
  }

  String? _extractInlineImage(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content =
        (candidates[0] as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null) return null;

    for (final part in parts) {
      final inlineData =
          (part as Map<String, dynamic>)['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final mimeType = inlineData['mimeType'] as String? ?? 'image/png';
        final base64 = inlineData['data'] as String?;
        if (base64 != null && base64.isNotEmpty) {
          return 'data:$mimeType;base64,$base64';
        }
      }
    }

    return null;
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      final response = await dio.get('/models');
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response?.statusCode != null) {
        final code = e.response!.statusCode!;
        return code != 401 && code != 403;
      }
      return false;
    }
  }

  List<Map<String, dynamic>> _toGeminiContents(
    List<Map<String, String>> messages,
  ) {
    final contents = <Map<String, dynamic>>[];
    final system = StringBuffer();

    for (final message in messages) {
      final role = message['role'] ?? 'user';
      final content = message['content'] ?? '';
      if (content.isEmpty) continue;
      if (role == 'system') {
        system.writeln(content);
        continue;
      }
      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': content},
        ],
      });
    }

    if (system.isNotEmpty) {
      contents.insert(0, {
        'role': 'user',
        'parts': [
          {'text': system.toString().trim()},
        ],
      });
    }

    return contents;
  }

  String _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final content =
        (candidates[0] as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null) return '';
    final buf = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'] as String?;
        if (text != null && text.isNotEmpty) buf.write(text);
      }
    }
    return buf.toString();
  }
}
