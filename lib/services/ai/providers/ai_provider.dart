import '../model_router.dart';

/// Abstract interface for AI providers (DeepSeek, OpenAI, Anthropic, etc.).
/// Each provider implements chat, streaming, and optionally image generation.
abstract class AiProvider {
  String get providerName;
  String get baseUrl;

  /// Maps a [ModelType] to the best available model name for this provider.
  String defaultModel(ModelType type);

  /// Non-streaming chat completion.
  Future<Map<String, dynamic>> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  });

  /// SSE streaming chat completion. Yields content delta strings.
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    required String apiKey,
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  });

  /// Generate an image from a text prompt.
  /// Returns the image URL, or null if not supported by this provider.
  Future<String?> generateImage({
    required String prompt,
    required String apiKey,
    String size = '1024x1024',
  }) async {
    return null;
  }

  /// Test the connection with the given API key.
  /// Returns true if the key is valid.
  Future<bool> testConnection(String apiKey);
}
