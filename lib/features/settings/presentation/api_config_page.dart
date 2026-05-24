import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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
      final useCustom = await ModelRouter.hasCustomKey(cfg.modelType);
      final key =
          useCustom ? (await ModelRouter.getApiKey(cfg.modelType)) : '';
      final provider = await ModelRouter.getProvider(cfg.modelType);

      setState(() {
        _useCustomKey[i] = useCustom;
        _keyControllers[i] = TextEditingController(text: key);
        _selectedProvider[i] =
            provider ?? (cfg.providers.isNotEmpty ? cfg.providers[0] : '');
      });
    }
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
      return Scaffold(
        appBar: AppBar(title: const Text('API 配置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('API 配置')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modelConfigs.length,
        itemBuilder: (_, i) => _buildModelCard(i),
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(config.icon, size: 24, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(config.label,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('使用自己的 API Key'),
                subtitle: Text(
                  useCustom ? '将使用您填写的 Key 调用' : '使用平台默认',
                  style: const TextStyle(fontSize: 12),
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
                  decoration: const InputDecoration(
                    labelText: '供应商',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              controller.clear();
                              _saveKey(index);
                            },
                          )
                        : null,
                  ),
                  obscureText: true,
                  onChanged: (_) => _saveKey(index),
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
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find, size: 18),
                    label: Text(testing ? '测试中...' : '测试连接'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveKey(int index) {
    final config = _modelConfigs[index];
    final key = _keyControllers[index]!.text.trim();
    if (key.isNotEmpty) {
      ModelRouter.setApiKey(config.modelType, key);
    }
  }

  Future<void> _testConnection(int index) async {
    final config = _modelConfigs[index];
    final key = _keyControllers[index]!.text.trim();

    if (key.isEmpty) {
      _showSnack('请先输入 API Key');
      return;
    }

    setState(() => _testing[index] = true);

    try {
      // Use the selected provider's real endpoint for testing
      final providerName = _selectedProvider[index] ?? config.providers.first;
      final provider = AiProviderRegistry.get(providerName);
      final success = await provider.testConnection(key);

      if (mounted) {
        if (success) {
          _showSnack('${config.label} 连接成功 ✅');
          ModelRouter.setApiKey(config.modelType, key);
          ModelRouter.setUseCustom(config.modelType, true);
          ModelRouter.setProvider(config.modelType, providerName);
        } else {
          _showSnack('连接失败 — 请检查 Key 和网络');
        }
      }
    } catch (e) {
      if (mounted) _showSnack('测试失败: $e');
    } finally {
      if (mounted) setState(() => _testing[index] = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已保存'),
        duration: Duration(seconds: 1),
        width: 120,
      ),
    );
  }
}
