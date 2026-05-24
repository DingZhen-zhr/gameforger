import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class StabilityProvider extends AiProvider {
  @override
  String get providerName => 'Stability';

  @override
  String get baseUrl => 'https://api.stability.ai/v1';

  @override
  String defaultModel(ModelType type) {
    // Stability is image-only; chat/code/music not supported.
    return '';
  }

  Dio _createDio(String apiKey) => Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
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
    throw UnsupportedError('Stability does not support chat completions');
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    throw UnsupportedError('Stability does not support chat completions');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);

    // Map size string to Stability dimensions
    final dimensions = _parseSize(size);

    final formData = FormData.fromMap({
      'prompt': prompt,
      'output_format': 'jpeg',
      ...dimensions,
    });

    final response = await dio.post(
      '/generation/stable-image-core/generate',
      data: formData,
      options: Options(headers: {'Accept': 'image/*'}),
    );

    // Stability returns the image directly; we save it or return a base64 URL
    if (response.statusCode == 200 && response.data is List<int>) {
      return 'data:image/jpeg;base64,${response.data}';
    }

    // If JSON response with URLs
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final artifacts = data['artifacts'] as List?;
      if (artifacts != null && artifacts.isNotEmpty) {
        final url = (artifacts[0] as Map<String, dynamic>)['url'] as String?;
        if (url != null) return url;
      }
      // Some endpoints return base64 in the response
      final base64 = (artifacts?.first as Map<String, dynamic>?)?.values
          .firstWhere((v) => v is String && v.length > 100,
              orElse: () => null) as String?;
      if (base64 != null && base64.length > 100) {
        return 'data:image/jpeg;base64,$base64';
      }
    }

    return null;
  }

  Map<String, dynamic> _parseSize(String size) {
    // Parse "1024x1024" → {"width": 1024, "height": 1024}
    final parts = size.split('x');
    if (parts.length == 2) {
      final w = int.tryParse(parts[0]) ?? 1024;
      final h = int.tryParse(parts[1]) ?? 1024;
      return {'width': w, 'height': h};
    }
    return {'width': 1024, 'height': 1024};
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      final response = await dio.get('/user/balance');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
