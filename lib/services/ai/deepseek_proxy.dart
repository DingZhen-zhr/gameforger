import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../credits/credit_service.dart';
import 'model_router.dart';
import 'providers/ai_provider_registry.dart';

/// Routes AI requests to the appropriate provider (custom API key)
/// or the platform-default Supabase Edge Function (credit-based).
class AiProxy {
  final CreditService _creditService = CreditService();

  AiProxy();

  Future<Map<String, dynamic>> chat({
    required List<Map<String, String>> messages,
    ModelType modelType = ModelType.chat,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final apiKey = await ModelRouter.getApiKey(modelType);

    if (apiKey.isNotEmpty) {
      final provider = await AiProviderRegistry.forModelType(modelType);
      return provider.chat(
        messages: messages,
        apiKey: apiKey,
        model: provider.defaultModel(modelType),
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }

    // Platform default → deduct credits, then call Edge Function
    await _tryDeduct(modelType);

    final provider = await AiProviderRegistry.forModelType(modelType);
    final model = provider.defaultModel(modelType);

    final resp = await Supabase.instance.client.functions
        .invoke(
          'ai-deepseek',
          body: {
            'messages': messages,
            'model': model,
            'temperature': temperature,
            'max_tokens': maxTokens,
          },
        )
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw Exception(
            'AI 服务响应超时（90秒），请稍后重试或到「设置 → API 配置」配置自定义 API Key 以获得更快响应。',
          ),
        );

    final data = resp.data;
    if (data is Map<String, dynamic>) {
      // Check for Edge Function error
      if (data.containsKey('error')) {
        final hint = data['hint'] as String?;
        final msg = data['error'] as String;
        throw Exception(hint != null ? '$msg\n$hint' : msg);
      }
      return data;
    }

    throw Exception('Unexpected Edge Function response: $data');
  }

  /// SSE streaming chat. When using a custom API key, true SSE chunks are
  /// yielded from the selected provider. When using the platform default
  /// Edge Function, the full response is yielded as a single chunk.
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    ModelType modelType = ModelType.chat,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    final apiKey = await ModelRouter.getApiKey(modelType);

    if (apiKey.isNotEmpty) {
      final provider = await AiProviderRegistry.forModelType(modelType);
      yield* provider.chatStream(
        messages: messages,
        apiKey: apiKey,
        model: provider.defaultModel(modelType),
        temperature: temperature,
        maxTokens: maxTokens,
      );
      return;
    }

    // Platform default → call Edge Function (credit deduction is handled inside chat())
    final result = await chat(
      messages: messages,
      modelType: modelType,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final content = result['choices']?[0]?['message']?['content'] as String?;
    if (content != null && content.isNotEmpty) {
      yield content;
    }
  }

  /// Generate an image through the configured provider.
  /// Returns the image URL, or null if the provider doesn't support images.
  Future<String?> generateImage({
    required String prompt,
    ModelType modelType = ModelType.image,
    String size = '1024x1024',
  }) async {
    final apiKey = await ModelRouter.getApiKey(modelType);

    if (apiKey.isEmpty) {
      // Platform default doesn't support image generation yet
      throw UnsupportedError(
        'Image generation requires a custom API key. '
        'Configure one in Settings → API Configuration.',
      );
    }

    await _tryDeduct(modelType);

    final provider = await AiProviderRegistry.forModelType(modelType);
    return provider.generateImage(prompt: prompt, apiKey: apiKey, size: size);
  }

  /// Generate music/audio through the configured provider.
  /// Returns an audio URL/data URL, or null if the provider doesn't support it.
  Future<String?> generateMusic({
    required String prompt,
    String? lyrics,
    bool instrumental = true,
    ModelType modelType = ModelType.music,
  }) async {
    final apiKey = await ModelRouter.getApiKey(modelType);

    if (apiKey.isEmpty) {
      throw UnsupportedError(
        'Music generation requires an API key. Configure one in Settings → API Configuration.',
      );
    }

    await _tryDeduct(modelType);

    final provider = await AiProviderRegistry.forModelType(modelType);
    return provider.generateMusic(
      prompt: prompt,
      apiKey: apiKey,
      lyrics: lyrics,
      instrumental: instrumental,
    );
  }

  /// Attempt credit deduction. Throws only for insufficient credits;
  /// network/other errors are silently ignored (grace period).
  Future<void> _tryDeduct(ModelType modelType) async {
    try {
      await _creditService.deduct(
        modelType.name,
        'AI ${modelType.name} generation',
      );
    } on DeductException catch (e) {
      if (e.required > 0) rethrow;
    } catch (_) {
      // Network or server error — allow the call through
    }
  }
}

/// Backward-compatible alias.
typedef DeepSeekProxy = AiProxy;
