import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class IdeogramProvider extends AiProvider {
  @override
  String get providerName => 'Ideogram';

  @override
  String get baseUrl => 'https://api.ideogram.ai';

  @override
  String defaultModel(ModelType type) => '';

  Dio _createDio(String apiKey) => Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Api-Key': apiKey,
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
    throw UnsupportedError('Ideogram does not support chat completions');
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    throw UnsupportedError('Ideogram does not support chat completions');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);
    final aspectRatio = _sizeToAspectRatio(size);

    final response = await dio.post(
      '/generate',
      data: {
        'image_request': {
          'prompt': prompt,
          'aspect_ratio': aspectRatio,
          'model': 'V_2_TURBO',
          'magic_prompt_option': 'AUTO',
        },
      },
    );

    final data = response.data as Map<String, dynamic>;
    final images = data['data'] as List?;
    if (images != null && images.isNotEmpty) {
      final url = (images[0] as Map<String, dynamic>)['url'] as String?;
      return url;
    }
    return null;
  }

  /// Converts size like "1024x1024" to Ideogram aspect ratio like "ASPECT_1_1".
  String _sizeToAspectRatio(String size) {
    final parts = size.split('x');
    if (parts.length != 2) return 'ASPECT_1_1';
    final w = int.tryParse(parts[0]) ?? 1024;
    final h = int.tryParse(parts[1]) ?? 1024;
    final ratio = w / h;

    if (ratio > 1.7) return 'ASPECT_16_9';
    if (ratio > 1.3) return 'ASPECT_3_2';
    if (ratio > 1.1) return 'ASPECT_4_3';
    if (ratio > 0.9) return 'ASPECT_1_1';
    if (ratio > 0.7) return 'ASPECT_3_4';
    if (ratio > 0.5) return 'ASPECT_2_3';
    return 'ASPECT_9_16';
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      // Use a minimal generate request to test authentication
      final response = await dio.post(
        '/generate',
        data: {
          'image_request': {
            'prompt': 'test',
            'aspect_ratio': 'ASPECT_1_1',
            'model': 'V_2_TURBO',
          },
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
