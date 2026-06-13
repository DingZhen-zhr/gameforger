import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';
import '../../../services/ai/model_router.dart';
import '../../../services/ai/providers/ai_provider_registry.dart';

class _ModelConfig {
  final String label;
  final IconData icon;
  final ModelType modelType;
  final String hint;
  _ModelConfig({
    required this.label,
    required this.icon,
    required this.modelType,
    this.hint = 'sk-...',
  });

  List<String> get providers => ModelRouter.providersFor(modelType);
}

final _modelConfigs = [
  _ModelConfig(
    label: '聊天模型',
    icon: Icons.chat,
    modelType: ModelType.chat,
    hint: 'sk-...',
  ),
  _ModelConfig(
    label: '生图模型',
    icon: Icons.palette,
    modelType: ModelType.image,
    hint: 'Enter your image API key',
  ),
  _ModelConfig(
    label: '代码/推理模型',
    icon: Icons.settings,
    modelType: ModelType.code,
    hint: 'sk-...',
  ),
  _ModelConfig(
    label: '音乐模型',
    icon: Icons.music_note,
    modelType: ModelType.music,
    hint: 'Enter your music API key',
  ),
];

class ApiConfigPage extends ConsumerStatefulWidget {
  const ApiConfigPage({super.key});

  @override
  ConsumerState<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends ConsumerState<ApiConfigPage> {
  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, bool> _useCustomKey = {};
  final Map<int, String> _selectedProvider = {};
  final Map<int, bool> _testing = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    for (var i = 0; i < _modelConfigs.length; i++) {
      final cfg = _modelConfigs[i];
      var useCustom = await ModelRouter.hasCustomKey(cfg.modelType);
      final key = useCustom
          ? await ModelRouter.getCustomApiKey(cfg.modelType)
          : '';
      if (useCustom && key.isEmpty) {
        await ModelRouter.setUseCustom(cfg.modelType, false);
        useCustom = false;
      }
      final provider = await ModelRouter.getProvider(cfg.modelType);
      final providers = cfg.providers;
      final selectedProvider = provider != null && providers.contains(provider)
          ? provider
          : (providers.isNotEmpty ? providers[0] : '');

      if (!mounted) return;
      setState(() {
        _useCustomKey[i] = useCustom;
        _keyControllers[i] = TextEditingController(text: key);
        _selectedProvider[i] = selectedProvider;
      });
      if (selectedProvider.isNotEmpty && selectedProvider != provider) {
        await ModelRouter.setProvider(cfg.modelType, selectedProvider);
      }
    }
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: CosmicBackground(
          child: Center(child: StarRingLoader(label: '加载模型路由')),
        ),
      );
    }

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: _modelConfigs.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _SettingsSubpageHeader(
                    title: 'API 配置',
                    subtitle: '模型路由与自定义密钥',
                  ),
                );
              }
              return _buildModelCard(i - 1);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModelCard(int index) {
    final config = _modelConfigs[index];
    final controller = _keyControllers[index]!;
    final useCustom = _useCustomKey[index] ?? false;
    final testing = _testing[index] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ForgeGlassCard(
        borderRadius: BorderRadius.circular(20),
        accent: AppTheme.primary,
        accentOpacity: 0.05,
        borderOpacity: 0.1,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(config.icon, size: 19, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.label,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                title: Text('使用自己的 API Key'),
                subtitle: Text(
                  useCustom ? '将使用您填写的 Key 调用' : _defaultRouteLabel(config),
                  style: TextStyle(fontSize: 12),
                ),
                value: useCustom,
                onChanged: (v) {
                  setState(() => _useCustomKey[index] = v);
                  ModelRouter.setUseCustom(config.modelType, v);
                  _showSaved();
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (useCustom) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvider[index],
                  decoration: InputDecoration(
                    labelText: '供应商',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: config.providers
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedProvider[index] = v);
                      ModelRouter.setProvider(config.modelType, v);
                      _showSaved();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: config.hint,
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              controller.clear();
                              _saveKey(index, normalizeController: false);
                            },
                          )
                        : null,
                  ),
                  obscureText: true,
                  onChanged: (_) => _saveKey(index, normalizeController: false),
                  onEditingComplete: () {
                    _saveKey(index);
                    FocusScope.of(context).nextFocus();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _routeNote(config.modelType),
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: testing ? null : () => _testConnection(index),
                    icon: testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.wifi_find, size: 18),
                    label: Text(
                      testing ? '测试中...' : '测试连接',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveKey(int index, {bool normalizeController = true}) {
    final config = _modelConfigs[index];
    final key = ModelRouter.sanitizeApiKey(_keyControllers[index]!.text);
    if (normalizeController && _keyControllers[index]!.text != key) {
      _keyControllers[index]!.value = TextEditingValue(
        text: key,
        selection: TextSelection.collapsed(offset: key.length),
      );
    }
    ModelRouter.setApiKey(config.modelType, key);
  }

  Future<void> _testConnection(int index) async {
    final config = _modelConfigs[index];
    final key = ModelRouter.sanitizeApiKey(_keyControllers[index]!.text);
    _keyControllers[index]!.text = key;

    if (key.isEmpty) {
      _showSnack('请先输入 API Key');
      return;
    }

    if (!ModelRouter.isValidApiKey(key)) {
      _showSnack('API Key 格式异常：请重新粘贴纯文本 Key，不能包含乱码字符');
      return;
    }

    final inferredProvider = _inferProvider(config, key);
    if (inferredProvider != null &&
        inferredProvider != _selectedProvider[index]) {
      setState(() => _selectedProvider[index] = inferredProvider);
      await ModelRouter.setProvider(config.modelType, inferredProvider);
    }

    if (!mounted) return;
    setState(() => _testing[index] = true);

    try {
      // Use the selected provider's real endpoint for testing
      final providerName = _selectedProvider[index] ?? config.providers.first;
      final provider = AiProviderRegistry.get(providerName);
      final success = await provider
          .testConnectionForModel(key, config.modelType)
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        if (success) {
          _showSnack('${config.label} · $providerName 连接成功');
          ModelRouter.setApiKey(config.modelType, key);
          ModelRouter.setUseCustom(config.modelType, true);
          ModelRouter.setProvider(config.modelType, providerName);
        } else {
          _showSnack('连接失败：请检查 $providerName Key、供应商和网络');
        }
      }
    } on TimeoutException {
      if (mounted) _showSnack('测试超时：15 秒内没有响应，请检查网络或供应商');
    } catch (e) {
      if (mounted) _showSnack('测试失败: $e');
    } finally {
      if (mounted) setState(() => _testing[index] = false);
    }
  }

  String? _inferProvider(_ModelConfig config, String key) {
    if (config.modelType == ModelType.image && key.startsWith('sk-')) {
      return 'GRS AI';
    }
    if (config.modelType == ModelType.image && key.startsWith('AIza')) {
      return 'Nano Banana';
    }
    if (key.startsWith('sk-api') &&
        config.providers.contains('MiniMax') &&
        config.modelType != ModelType.image) {
      return 'MiniMax';
    }
    return null;
  }

  String _defaultRouteLabel(_ModelConfig config) {
    switch (config.modelType) {
      case ModelType.image:
        return '默认使用 GRS AI 生成透明背景游戏图片素材';
      case ModelType.music:
        return '默认使用 MiniMax 生成游戏配乐';
      case ModelType.chat:
      case ModelType.code:
        return '使用平台默认路由';
    }
  }

  String _routeNote(ModelType type) {
    switch (type) {
      case ModelType.chat:
        return '用于工作台对话与苏格拉底式追问。';
      case ModelType.image:
        return '默认已内置 GRS AI，用于生成透明背景、可直接嵌入游戏的图片素材。自填 sk- Key 会自动切到 GRS AI；Google/Gemini AIza Key 会自动切到 Nano Banana。';
      case ModelType.code:
        return '用于游戏代码生成与预览页 AI 修改，属于推理/代码路线；MiniMax sk-api Key 会自动识别。';
      case ModelType.music:
        return '默认已内置 MiniMax music-2.6-free，用于预览页素材面板生成游戏配乐。';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保存'),
        duration: Duration(seconds: 1),
        width: 120,
      ),
    );
  }
}

class _SettingsSubpageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsSubpageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ForgeIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.maybePop(context),
          tooltip: '返回',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
