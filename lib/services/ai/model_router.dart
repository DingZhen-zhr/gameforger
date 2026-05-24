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
};

class ModelRouter {
  static const _storage = FlutterSecureStorage();

  static String _keyKey(ModelType type) => 'api_key_${type.name}';
  static String _useCustomKey(ModelType type) =>
      'use_custom_${type.name}';
  static String _providerKey(ModelType type) =>
      'provider_${type.name}';

  // --------------- API Key Management ---------------

  static Future<String> getApiKey(ModelType type) async {
    final useCustom = await _storage.read(key: _useCustomKey(type));
    if (useCustom == 'true') {
      final key = await _storage.read(key: _keyKey(type));
      if (key != null && key.isNotEmpty) return key;
    }
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
    return await _storage.read(key: _providerKey(type));
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
      case 'Gemini':
        return ProviderType.gemini;
      case '豆包':
      case 'Doubao':
        return ProviderType.doubao;
      default:
        return ProviderType.deepseek;
    }
  }

  /// Returns suggested provider names for a given [ModelType].
  static List<String> providersFor(ModelType type) {
    switch (type) {
      case ModelType.chat:
        return ['DeepSeek', 'OpenAI', 'Claude'];
      case ModelType.image:
        return ['DALL·E 3', 'Stable Diffusion', 'Flux', 'Ideogram', 'Gemini', '豆包'];
      case ModelType.code:
        return ['DeepSeek', 'Claude', 'OpenAI'];
      case ModelType.music:
        return ['Suno', 'Udio'];
    }
  }

  // --------------- Cleanup ---------------

  static Future<void> clear(ModelType type) async {
    await _storage.delete(key: _keyKey(type));
    await _storage.delete(key: _useCustomKey(type));
    await _storage.delete(key: _providerKey(type));
  }
}
