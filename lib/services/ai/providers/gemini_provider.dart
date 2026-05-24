import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class GeminiProvider extends AiProvider {
  @override
  String get providerName => 'Gemini';

  @override
  String get baseUrl => 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String defaultModel(ModelType type) => '';

  Dio _createDio(String apiKey) => Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-goog-api-key': apiKey,
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
    throw UnsupportedError('Gemini Nano Banana does not support chat completions');
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    throw UnsupportedError('Gemini Nano Banana does not support chat completions');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);

    final response = await dio.post(
      '/models/gemini-2.5-flash-image:generateContent',
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['IMAGE', 'TEXT'],
        },
      },
    );

    final data = response.data as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = (candidates[0] as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null) return null;

    for (final part in parts) {
      final inlineData = (part as Map<String, dynamic>)['inlineData'] as Map<String, dynamic>?;
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
      final response = await dio.post(
        '/models/gemini-2.5-flash-image:generateContent',
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'test'}
              ]
            }
          ],
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response?.statusCode != null) {
        final code = e.response!.statusCode!;
        return code != 401 && code != 403;
      }
      return false;
    }
  }
}
