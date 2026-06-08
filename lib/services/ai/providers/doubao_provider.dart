import 'package:dio/dio.dart';
import '../model_router.dart';
import 'ai_provider.dart';

class DoubaoProvider extends AiProvider {
  @override
  String get providerName => 'Doubao';

  @override
  String get baseUrl => 'https://ark.cn-beijing.volces.com/api/v3';

  @override
  String defaultModel(ModelType type) => '';

  Dio _createDio(String apiKey) {
    final authHeader = ModelRouter.bearerHeader(apiKey);
    if (authHeader == null) {
      throw const FormatException('Invalid Doubao API key format.');
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
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
    throw UnsupportedError('Doubao Seedream does not support chat completions');
  }

  @override
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    throw UnsupportedError('Doubao Seedream does not support chat completions');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    final dio = _createDio(apiKey);
    final apiSize = _appSizeToApiSize(size);

    final response = await dio.post(
      '/images/generations',
      data: {
        'model': 'doubao-seedream-4-5-251128',
        'prompt': prompt,
        'size': apiSize,
        'response_format': 'url',
        'watermark': false,
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

  /// Maps internal size like "1024x1024" to Doubao API size tokens.
  String _appSizeToApiSize(String size) {
    final parts = size.split('x');
    if (parts.length != 2) return '2K';
    final w = int.tryParse(parts[0]) ?? 1024;
    final h = int.tryParse(parts[1]) ?? 1024;
    final maxDim = w > h ? w : h;

    if (maxDim >= 2048) return '4K';
    if (maxDim >= 1536) return '2K';
    return '1K';
  }

  @override
  Future<bool> testConnection(String apiKey) async {
    try {
      final dio = _createDio(apiKey);
      final response = await dio.post(
        '/images/generations',
        data: {
          'model': 'doubao-seedream-4-5-251128',
          'prompt': 'test',
          'size': '1K',
          'response_format': 'url',
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
