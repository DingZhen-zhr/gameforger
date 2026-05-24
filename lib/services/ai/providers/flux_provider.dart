import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class FluxProvider extends AiProvider {
  @override
  String get providerName => 'Flux';

  @override
  String get baseUrl => 'https://api.bfl.ml/v1';

  @override
  String defaultModel(ModelType type) => '';

  Dio _createDio(String apiKey) => Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-key': apiKey,
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
    throw UnsupportedError('Flux does not support chat completions');
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    throw UnsupportedError('Flux does not support chat completions');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);
    final dimensions = _parseSize(size);

    // Submit generation request
    final submitResponse = await dio.post(
      '/flux-pro-1.1',
      data: {
        'prompt': prompt,
        'width': dimensions['width'],
        'height': dimensions['height'],
        'prompt_upsampling': false,
        'safety_tolerance': 5,
      },
    );

    final id = (submitResponse.data as Map<String, dynamic>)['id'] as String?;
    if (id == null) return null;

    // Poll for result
    for (var i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final resultResponse = await dio.get('/get_result', queryParameters: {
        'id': id,
      });

      final data = resultResponse.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'Ready') {
        final result = data['result'] as Map<String, dynamic>?;
        final sample = result?['sample'] as String?;
        // Some Flux endpoints return a URL directly
        if (sample != null && sample.isNotEmpty) return sample;
        // Fallback: check for url field
        final url = result?['url'] as String?;
        return url;
      }

      if (status == 'Failed' || status == 'Error') {
        return null;
      }
    }

    throw Exception('Flux image generation timed out after 2 minutes');
  }

  Map<String, dynamic> _parseSize(String size) {
    final parts = size.split('x');
    if (parts.length == 2) {
      return {
        'width': int.tryParse(parts[0]) ?? 1024,
        'height': int.tryParse(parts[1]) ?? 1024,
      };
    }
    return {'width': 1024, 'height': 1024};
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      // Simple ping — try a cheap endpoint
      final response = await dio.get('/get_result', queryParameters: {
        'id': 'test',
      });
      // Even a 404 means the API key is valid and the endpoint is reachable
      return response.statusCode != 401 && response.statusCode != 403;
    } catch (e) {
      if (e is DioException && e.response?.statusCode != null) {
        final code = e.response!.statusCode!;
        return code != 401 && code != 403;
      }
      return false;
    }
  }
}
