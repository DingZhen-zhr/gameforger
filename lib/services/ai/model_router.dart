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
    ModelType.image: 'sk-7d2d0f0d01af4fa294131f550fe0eef4',
    ModelType.music:
        'sk-api-I1RwQUd4S-gYbfrqZR6Kv9QPycsBkBPhoiAJCeR6CSaPrQBdgCCKTdF2HRIWW5mLMlaqYtwSeNtSiEHEFemFcGlbX_iRaOJ41_DW8zHa0MYh_e02-zwPeFo',
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

  static String sanitizeApiKey(String key) {
    final buffer = StringBuffer();
    for (final rune in key.runes) {
      if (_isIgnorableKeyRune(rune)) continue;
      buffer.writeCharCode(rune);
    }
    return buffer.toString().trim();
  }

  static bool _isIgnorableKeyRune(int rune) {
    return rune == 0x09 ||
        rune == 0x0A ||
        rune == 0x0B ||
        rune == 0x0C ||
        rune == 0x0D ||
        rune == 0x20 ||
        rune == 0xA0 ||
        rune == 0x1680 ||
        rune == 0x180E ||
        (rune >= 0x2000 && rune <= 0x200D) ||
        rune == 0x2028 ||
        rune == 0x2029 ||
        rune == 0x202F ||
        rune == 0x205F ||
        rune == 0x3000 ||
        rune == 0xFEFF;
  }

  static bool isValidApiKey(String key) {
    final sanitized = sanitizeApiKey(key);
    if (sanitized.isEmpty) return false;
    return sanitized.codeUnits.every((unit) => unit >= 33 && unit <= 126);
  }

  static String? bearerHeader(String key) {
    final sanitized = sanitizeApiKey(key);
    if (!isValidApiKey(sanitized)) return null;
    return 'Bearer $sanitized';
  }

  static Future<String> getApiKey(ModelType type) async {
    final useCustom = await _storage.read(key: _useCustomKey(type));
    if (useCustom == 'true') {
      final key = await _storage.read(key: _keyKey(type));
      if (key != null && key.isNotEmpty) {
        final sanitized = sanitizeApiKey(key);
        if (isValidApiKey(sanitized)) return sanitized;
      }
    }
    // Fall back to development default (e.g. Claude key compiled in).
    final defaultKey = defaultApiKeys[type];
    if (defaultKey != null && defaultKey.isNotEmpty) {
      final sanitized = sanitizeApiKey(defaultKey);
      if (isValidApiKey(sanitized)) return sanitized;
    }
    return '';
  }

  static Future<bool> hasCustomKey(ModelType type) async {
    final val = await _storage.read(key: _useCustomKey(type));
    return val == 'true';
  }

  static Future<String> getCustomApiKey(ModelType type) async {
    final key = await _storage.read(key: _keyKey(type));
    if (key == null || key.isEmpty) return '';
    final sanitized = sanitizeApiKey(key);
    return isValidApiKey(sanitized) ? sanitized : '';
  }

  static Future<void> setApiKey(ModelType type, String key) async {
    await _storage.write(key: _keyKey(type), value: sanitizeApiKey(key));
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
