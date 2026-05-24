import '../model_router.dart';
import 'ai_provider.dart';
import 'deepseek_provider.dart';
import 'openai_provider.dart';
import 'anthropic_provider.dart';
import 'stability_provider.dart';
import 'flux_provider.dart';
import 'ideogram_provider.dart';
import 'gemini_provider.dart';
import 'doubao_provider.dart';

/// Maps provider name strings to [AiProvider] instances.
class AiProviderRegistry {
  AiProviderRegistry._();

  static final Map<String, AiProvider> _providers = {
    'DeepSeek': DeepSeekProvider(),
    'OpenAI': OpenAIProvider(),
    'Claude': AnthropicProvider(),
    'GPT-4o': OpenAIProvider(),
    'Stable Diffusion': StabilityProvider(),
    'DALL·E 3': OpenAIProvider(),
    'Flux': FluxProvider(),
    'Ideogram': IdeogramProvider(),
    'Gemini': GeminiProvider(),
    '豆包': DoubaoProvider(),
  };

  /// Returns the [AiProvider] for the given provider name.
  /// Falls back to DeepSeek if the name is unknown.
  static AiProvider get(String? providerName) {
    return _providers[providerName] ?? DeepSeekProvider();
  }

  /// Returns the [AiProvider] configured for the given [ModelType].
  /// Reads the stored provider name from [ModelRouter], falling back to DeepSeek.
  static Future<AiProvider> forModelType(ModelType type) async {
    final name = await ModelRouter.getProvider(type);
    return get(name);
  }

  /// All registered provider names for display in settings dropdowns.
  static List<String> get providerNames => _providers.keys.toList();
}
