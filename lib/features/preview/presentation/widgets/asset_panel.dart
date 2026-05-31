import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/ai/model_router.dart';
import '../../../../services/ai/providers/ai_provider_registry.dart';
import '../providers/preview_provider.dart';

class AssetPanel extends ConsumerStatefulWidget {
  final String projectId;
  final void Function(String newHtml)? onApplyCode;

  const AssetPanel({super.key, required this.projectId, this.onApplyCode});

  @override
  ConsumerState<AssetPanel> createState() => _AssetPanelState();
}

class _AssetPanelState extends ConsumerState<AssetPanel> {
  bool _isGenerating = false;
  String? _generatedImageUrl;
  String? _generationError;

  @override
  Widget build(BuildContext context) {
    final html = ref.watch(previewProvider(widget.projectId)).htmlCode;
    final assets = _extractAssets(html);

    if (assets.isEmpty && _generatedImageUrl == null) {
      return Container(
        color: AppTheme.bgDark,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 32,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '暂无素材',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '游戏代码中没有检测到图片、音频\n或外部资源，所有内容由 Canvas 绘制',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAiGenerateSection(context),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.bgDark,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          if (assets.colors.isNotEmpty)
            _buildColorSection(context, html, assets.colors),
          if (assets.objects.isNotEmpty)
            _buildObjectSection(context, html, assets.objects),
          if (assets.externalUrls.isNotEmpty)
            _buildUrlSection(context, html, assets.externalUrls),
          if (_generatedImageUrl != null) _buildGeneratedImage(context),
          const SizedBox(height: 12),
          _buildAiGenerateSection(context),
        ],
      ),
    );
  }

  // ─── Color Palette (editable) ──────────────────────────────────────

  Widget _buildColorSection(
    BuildContext context,
    String html,
    List<ColorInfo> colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('调色板', '点击色块编辑或替换'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((c) {
              return GestureDetector(
                onTap: () => _editColor(context, html, c),
                child: Tooltip(
                  message: '${c.label} — 点击编辑',
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.outlineDark.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _editColor(BuildContext context, String html, ColorInfo colorInfo) {
    final hexController = TextEditingController(
      text: colorInfo.label.replaceFirst('#', ''),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorInfo.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '编辑颜色',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hexController,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                prefixText: '#',
                prefixStyle: const TextStyle(color: AppTheme.textSecondary),
                hintText: '输入十六进制颜色值',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '替换所有 "$colorInfo.label" 为新的颜色值',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final newHex = hexController.text.trim();
              if (newHex.isNotEmpty) {
                _replaceColorInHtml(html, colorInfo.label, '#$newHex');
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('替换全部'),
          ),
        ],
      ),
    );
  }

  void _replaceColorInHtml(String html, String oldHex, String newHex) {
    final updated = html.replaceAll(oldHex, newHex);
    if (updated != html) {
      ref.read(previewProvider(widget.projectId).notifier).updateCode(updated);
      widget.onApplyCode?.call(updated);
    }
  }

  // ─── Game Objects (editable) ────────────────────────────────────────

  Widget _buildObjectSection(
    BuildContext context,
    String html,
    List<ObjectInfo> objects,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('游戏对象', '点击修改名称'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: objects.map((o) {
              return GestureDetector(
                onTap: () => _editObjectName(context, html, o),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.outlineDark.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(o.icon, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        o.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _editObjectName(
    BuildContext context,
    String html,
    ObjectInfo objectInfo,
  ) {
    final controller = TextEditingController(text: objectInfo.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Row(
          children: [
            Icon(objectInfo.icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text(
              '编辑对象名称',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '输入新的对象名称',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '注意：重命名可能影响游戏逻辑，请确认代码中的变量名一致',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != objectInfo.name) {
                _replaceObjectInHtml(html, objectInfo.name, newName);
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('重命名'),
          ),
        ],
      ),
    );
  }

  void _replaceObjectInHtml(String html, String oldName, String newName) {
    final updated = html.replaceAll(oldName, newName);
    if (updated != html) {
      ref.read(previewProvider(widget.projectId).notifier).updateCode(updated);
      widget.onApplyCode?.call(updated);
    }
  }

  // ─── External URLs (editable) ──────────────────────────────────────

  Widget _buildUrlSection(
    BuildContext context,
    String html,
    List<UrlInfo> urls,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('外部资源', '点击编辑或替换 URL'),
          const SizedBox(height: 8),
          ...urls.map(
            (u) => GestureDetector(
              onTap: () => _editUrl(context, html, u),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      u.isAudio ? Icons.audiotrack : Icons.image,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        u.url,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.edit,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editUrl(BuildContext context, String html, UrlInfo urlInfo) {
    final controller = TextEditingController(text: urlInfo.url);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Row(
          children: [
            Icon(
              urlInfo.isAudio ? Icons.audiotrack : Icons.image,
              color: AppTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              '编辑资源 URL',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '输入新的资源 URL',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty && newUrl != urlInfo.url) {
                final updated = html.replaceAll(urlInfo.url, newUrl);
                ref
                    .read(previewProvider(widget.projectId).notifier)
                    .updateCode(updated);
                widget.onApplyCode?.call(updated);
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('替换'),
          ),
        ],
      ),
    );
  }

  // ─── AI Image Generation ────────────────────────────────────────────

  Widget _buildAiGenerateSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineDark.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text(
                'AI 图片生成',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isGenerating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_generationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _generationError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;
              final input = TextField(
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '描述你要生成的图片素材...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (prompt) => _generateImage(prompt),
              );

              final button = SizedBox(
                height: 36,
                width: compact ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () {
                          _showGenerateDialog(context);
                        },
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text('生成', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(72, 36),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [input, const SizedBox(height: 8), button],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 8),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    final promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI 生成图片素材',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '描述你想要生成的图片，AI 将为你创建游戏素材。\n\n'
                  '支持 DALL·E 3、Stable Diffusion、Flux、Ideogram、Gemini、豆包。\n'
                  '需要在「设置 → API 配置」中配置相应的 API Key。',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
                  autofocus: true,
                  maxLines: 4,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        '例如：pixel art game character, 32x32, side view, neon spaceship',
                    hintStyle: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _generateImage(promptController.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('开始生成'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateImage(String prompt) async {
    if (prompt.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final apiKey = await ModelRouter.getApiKey(ModelType.image);
      if (apiKey.isEmpty) {
        setState(() {
          _generationError =
              '请先在「设置 → API 配置」中配置图片生成 API Key'
              '\n支持 Stability AI 或 OpenAI (DALL·E 3)';
        });
        return;
      }

      final provider = await AiProviderRegistry.forModelType(ModelType.image);
      final imageUrl = await provider.generateImage(
        prompt: prompt,
        apiKey: apiKey,
        size: '1024x1024',
      );

      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _generatedImageUrl = imageUrl;
        });
      } else {
        setState(() {
          _generationError = '图片生成失败，请检查 API Key 和网络连接';
        });
      }
    } catch (e) {
      setState(() {
        _generationError = '生成失败: $e';
      });
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Widget _buildGeneratedImage(BuildContext context) {
    final isBase64 = _generatedImageUrl!.startsWith('data:image');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('AI 生成图片', '点击嵌入到游戏代码中'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isBase64
                ? Image.memory(
                    base64Decode(_generatedImageUrl!.split(',').last),
                    height: 200,
                    fit: BoxFit.contain,
                  )
                : Image.network(
                    _generatedImageUrl!,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 100,
                      color: AppTheme.surfaceVariant,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(
                icon: Icons.code,
                label: '嵌入代码',
                onTap: () => _embedImageInCode(),
              ),
              _actionChip(
                icon: Icons.delete_outline,
                label: '清除',
                onTap: () => setState(() => _generatedImageUrl = null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _embedImageInCode() {
    if (_generatedImageUrl == null) return;
    final html = ref.read(previewProvider(widget.projectId)).htmlCode;

    // Embed as a JS image loader in the game
    final imageLoader =
        '''
<script>
// AI-generated game asset
const aiGeneratedImage = new Image();
aiGeneratedImage.src = '$_generatedImageUrl';
</script>
''';

    final updated = html.replaceFirst('</head>', '$imageLoader</head>');
    ref.read(previewProvider(widget.projectId).notifier).updateCode(updated);
    widget.onApplyCode?.call(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('图片已嵌入游戏代码，可通过 aiGeneratedImage 引用'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Extraction Logic ───────────────────────────────────────────────

  static _AssetData _extractAssets(String html) {
    final colors = <ColorInfo>[];
    final objects = <ObjectInfo>[];
    final urls = <UrlInfo>[];

    final hexPattern = RegExp("'#([0-9a-fA-F]{3,8})'|\"#([0-9a-fA-F]{3,8})\"");
    final seenColors = <String>{};
    for (final match in hexPattern.allMatches(html)) {
      final hex = (match.group(1) ?? match.group(2))!;
      final fullHex = hex.length == 3 || hex.length == 4
          ? hex.split('').map((c) => '$c$c').join()
          : hex;
      if (seenColors.add(fullHex) && seenColors.length <= 12) {
        final rgb = _hexToColor(fullHex);
        colors.add(ColorInfo(color: rgb, label: '#$fullHex'));
      }
    }

    final objectPatterns = <String, IconData>{
      'player': Icons.person,
      'Player': Icons.person,
      'enemy': Icons.catching_pokemon,
      'Enemy': Icons.catching_pokemon,
      'boss': Icons.dangerous,
      'coin': Icons.monetization_on,
      'Coin': Icons.monetization_on,
      'star': Icons.star,
      'Star': Icons.star,
      'platform': Icons.landscape,
      'Platform': Icons.landscape,
      'bullet': Icons.gps_fixed,
      'Bullet': Icons.gps_fixed,
      'particle': Icons.auto_awesome,
      'Particle': Icons.auto_awesome,
      'obstacle': Icons.warning,
      'Obstacle': Icons.warning,
      'collectible': Icons.diamond,
      'Collectible': Icons.diamond,
      'item': Icons.category,
      'Item': Icons.category,
      'heart': Icons.favorite,
      'Heart': Icons.favorite,
      'goal': Icons.flag,
      'Goal': Icons.flag,
      'portal': Icons.blur_on,
      'Portal': Icons.blur_on,
    };
    for (final entry in objectPatterns.entries) {
      if (html.contains(entry.key)) {
        final name = entry.key[0].toUpperCase() + entry.key.substring(1);
        if (!objects.any((o) => o.name == name)) {
          objects.add(ObjectInfo(name: name, icon: entry.value));
        }
      }
      if (objects.length >= 12) break;
    }

    final urlPattern = RegExp("https?://[^\\s\"'<>]+");
    for (final match in urlPattern.allMatches(html)) {
      final url = match.group(0)!;
      if (urls.length >= 6) break;
      if (!urls.any((u) => u.url == url)) {
        urls.add(
          UrlInfo(
            url: url,
            isAudio:
                url.contains('.mp3') ||
                url.contains('.wav') ||
                url.contains('.ogg'),
          ),
        );
      }
    }

    return _AssetData(colors: colors, objects: objects, externalUrls: urls);
  }

  static Color _hexToColor(String hex) {
    final h = hex.padLeft(6, 'f');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class ColorInfo {
  final Color color;
  final String label;
  const ColorInfo({required this.color, required this.label});
}

class ObjectInfo {
  final String name;
  final IconData icon;
  const ObjectInfo({required this.name, required this.icon});
}

class UrlInfo {
  final String url;
  final bool isAudio;
  const UrlInfo({required this.url, required this.isAudio});
}

class _AssetData {
  final List<ColorInfo> colors;
  final List<ObjectInfo> objects;
  final List<UrlInfo> externalUrls;

  const _AssetData({
    this.colors = const [],
    this.objects = const [],
    this.externalUrls = const [],
  });

  bool get isEmpty => colors.isEmpty && objects.isEmpty && externalUrls.isEmpty;
}
