import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ModelType { chat, image, code, music }

/// Supported AI provider types for routing.
enum ProviderType {
  deepseek,
  openai,
  anthropic,
  stability,
  flux,
  ideogram,
  gemini,
  doubao,
  minimax,
  grsai,
}

/// Maps [ProviderType] to its display name.
const Map<ProviderType, String> providerTypeNames = {
  ProviderType.deepseek: 'DeepSeek',
  ProviderType.openai: 'OpenAI',
  ProviderType.anthropic: 'Claude',
  ProviderType.stability: 'Stable Diffusion',
  ProviderType.flux: 'Flux',
  ProviderType.ideogram: 'Ideogram',
  ProviderType.gemini: 'Gemini',
  ProviderType.doubao: '豆包',
  ProviderType.minimax: 'MiniMax',
  ProviderType.grsai: 'GRS AI',
};

class ModelRouter {
  static const _storage = FlutterSecureStorage();

  /// Prototype defaults (no custom API key configured in-app).
  /// Override in Settings → API Configuration at runtime.
  /// These are compiled into the client build, so production releases should
  /// replace them with a backend proxy or environment-injected keys.
  static const Map<ModelType, String> defaultApiKeys = {
    ModelType.image: '',
    ModelType.music: '',
  };

  static const Map<ModelType, String> defaultProviders = {
    ModelType.chat: 'DeepSeek',
    ModelType.image: 'GRS AI',
    ModelType.code: 'DeepSeek',
    ModelType.music: 'MiniMax',
  };

  /// Default base URLs for each model type (e.g. API proxy endpoints).
  static const Map<ModelType, String> defaultBaseUrls = {
    ModelType.chat: 'https://api.aicodemirror.com/api/codex/backend-api',
  };

  static String _baseUrlKey(ModelType type) => 'base_url_${type.name}';

  /// Returns the stored base URL for [type], falling back to the default.
  static Future<String?> getBaseUrl(ModelType type) async {
    final stored = await _storage.read(key: _baseUrlKey(type));
    if (stored != null && stored.isNotEmpty) return stored;
    return defaultBaseUrls[type];
  }

  static Future<void> setBaseUrl(ModelType type, String url) async {
    await _storage.write(key: _baseUrlKey(type), value: url);
  }

  static String _keyKey(ModelType type) => 'api_key_${type.name}';
  static String _useCustomKey(ModelType type) => 'use_custom_${type.name}';
  static String _providerKey(ModelType type) => 'provider_${type.name}';

  // --------------- API Key Management ---------------

  static Future<String> getApiKey(ModelType type) async {
    final useCustom = await _storage.read(key: _useCustomKey(type));
    if (useCustom == 'true') {
      final key = await _storage.read(key: _keyKey(type));
      if (key != null && key.isNotEmpty) return key;
    }
    // Fall back to development default (e.g. Claude key compiled in).
    final defaultKey = defaultApiKeys[type];
    if (defaultKey != null && defaultKey.isNotEmpty) return defaultKey;
    return '';
  }

  static Future<bool> hasCustomKey(ModelType type) async {
    final val = await _storage.read(key: _useCustomKey(type));
    return val == 'true';
  }

  static Future<void> setApiKey(ModelType type, String key) async {
    await _storage.write(key: _keyKey(type), value: key);
  }

  static Future<void> setUseCustom(ModelType type, bool value) async {
    await _storage.write(key: _useCustomKey(type), value: value.toString());
  }

  // --------------- Provider Routing ---------------

  /// Returns the stored provider name for [type] (e.g. "DeepSeek", "OpenAI").
  static Future<String?> getProvider(ModelType type) async {
    final useCustom = await _storage.read(key: _useCustomKey(type));
    if (useCustom != 'true') return defaultProviders[type];

    final stored = await _storage.read(key: _providerKey(type));
    if (stored != null && stored.isNotEmpty) return stored;
    // Fall back to development default (e.g. Claude).
    return defaultProviders[type];
  }

  static Future<void> setProvider(ModelType type, String provider) async {
    await _storage.write(key: _providerKey(type), value: provider);
  }

  /// Returns the [ProviderType] for the given [ModelType].
  /// Falls back to [ProviderType.deepseek] if not set.
  static Future<ProviderType> getProviderType(ModelType type) async {
    final name = await getProvider(type);
    return _parseProviderType(name);
  }

  /// Parses a provider display name into a [ProviderType].
  static ProviderType _parseProviderType(String? name) {
    switch (name) {
      case 'OpenAI':
      case 'GPT-4o':
      case 'DALL·E 3':
        return ProviderType.openai;
      case 'Claude':
      case 'Anthropic':
        return ProviderType.anthropic;
      case 'Stable Diffusion':
      case 'Stability':
        return ProviderType.stability;
      case 'Flux':
        return ProviderType.flux;
      case 'Ideogram':
        return ProviderType.ideogram;
      case 'Nano Banana':
      case 'Nano Banana (Gemini)':
      case 'Gemini':
        return ProviderType.gemini;
      case '豆包':
      case 'Doubao':
        return ProviderType.doubao;
      case 'MiniMax':
        return ProviderType.minimax;
      case 'GRS AI':
      case 'GRSAI':
        return ProviderType.grsai;
      default:
        return ProviderType.deepseek;
    }
  }

  /// Returns suggested provider names for a given [ModelType].
  static List<String> providersFor(ModelType type) {
    switch (type) {
      case ModelType.chat:
        return ['DeepSeek', 'OpenAI', 'Claude', 'Gemini', 'MiniMax'];
      case ModelType.image:
        return [
          'GRS AI',
          'Nano Banana',
          'DALL·E 3',
          'Stable Diffusion',
          'Flux',
          'Ideogram',
          '豆包',
        ];
      case ModelType.code:
        return ['DeepSeek', 'Claude', 'OpenAI', 'Gemini', 'MiniMax'];
      case ModelType.music:
        return ['MiniMax', 'OpenAI', 'Gemini', 'DeepSeek', 'Claude'];
    }
  }

  // --------------- Cleanup ---------------

  static Future<void> clear(ModelType type) async {
    await _storage.delete(key: _keyKey(type));
    await _storage.delete(key: _useCustomKey(type));
    await _storage.delete(key: _providerKey(type));
  }
}
