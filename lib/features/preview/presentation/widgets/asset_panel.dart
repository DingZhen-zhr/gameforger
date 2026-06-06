import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/ai/model_router.dart';
import '../../../../services/ai/providers/ai_provider_registry.dart';

class AssetPanel extends StatefulWidget {
  final String projectId;
  final String htmlCode;
  final void Function(String newHtml)? onApplyCode;

  const AssetPanel({
    super.key,
    required this.projectId,
    required this.htmlCode,
    this.onApplyCode,
  });

  @override
  State<AssetPanel> createState() => _AssetPanelState();
}

class _AssetPanelState extends State<AssetPanel> {
  final _imagePromptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedImageUrl;
  Uint8List? _generatedImageBytes;
  String? _generatedImageFilePath;
  String? _generatedMusicUrl;
  String? _generationError;
  int _generationRunId = 0;

  @override
  void dispose() {
    _generationRunId++;
    _imagePromptController.dispose();
    super.dispose();
  }

  bool _isActiveGeneration(int runId) {
    return mounted && runId == _generationRunId;
  }

  void _applyUpdatedCode(String updated) {
    widget.onApplyCode?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final html = widget.htmlCode;
    final assets = _extractAssets(html);

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
          if (assets.isEmpty &&
              _generatedImageUrl == null &&
              _generatedMusicUrl == null)
            _buildEmptyAssetsMessage(context),
          if (assets.colors.isNotEmpty)
            _buildColorSection(context, html, assets.colors),
          if (assets.objects.isNotEmpty)
            _buildObjectSection(context, html, assets.objects),
          if (assets.externalUrls.isNotEmpty)
            _buildUrlSection(context, html, assets.externalUrls),
          if (_generatedImageUrl != null)
            _buildGeneratedImage(context, assets.objects),
          if (_generatedMusicUrl != null) _buildGeneratedMusic(context),
          const SizedBox(height: 12),
          _buildAiGenerateSection(context),
        ],
      ),
    );
  }

  Widget _buildEmptyAssetsMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
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
      _applyUpdatedCode(updated);
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
      _applyUpdatedCode(updated);
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
                _applyUpdatedCode(updated);
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

  // ─── AI Asset Generation ────────────────────────────────────────────

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
                'AI 素材生成',
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
                controller: _imagePromptController,
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
                onSubmitted: (_) => _startImageGeneration(),
              );

              final button = SizedBox(
                height: 36,
                width: compact ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _startImageGeneration,
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
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppTheme.outlineDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AI 配乐生成',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '默认使用 MiniMax 生成游戏 BGM',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );

              final button = SizedBox(
                height: 36,
                width: compact ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () {
                          _showMusicGenerateDialog(context);
                        },
                  icon: const Icon(Icons.music_note, size: 16),
                  label: const Text('生成配乐', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(92, 36),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [copy, const SizedBox(height: 8), button],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: copy),
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

  Future<void> _startImageGeneration() async {
    final imagePrompt = _imagePromptController.text.trim();
    if (imagePrompt.isEmpty) {
      setState(() {
        _generationError = '请输入图片素材描述';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    await _generateImage(imagePrompt);
  }

  Future<void> _generateImage(String prompt) async {
    if (prompt.isEmpty || _isGenerating) return;
    final runId = ++_generationRunId;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final apiKey = await ModelRouter.getApiKey(ModelType.image);
      if (!_isActiveGeneration(runId)) return;
      if (apiKey.isEmpty) {
        setState(() {
          _generationError =
              '请先在「设置 → API 配置」中配置图片生成 API Key'
              '\n支持 Nano Banana、DALL·E 3、Stability、Flux、Ideogram、豆包';
        });
        return;
      }

      final provider = await AiProviderRegistry.forModelType(ModelType.image);
      if (!_isActiveGeneration(runId)) return;
      final imageUrl = await provider
          .generateImage(prompt: prompt, apiKey: apiKey, size: '1024x1024')
          .timeout(const Duration(seconds: 300));

      if (!_isActiveGeneration(runId)) return;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final materialized = await _materializeImageAsset(imageUrl, runId);
        if (!_isActiveGeneration(runId)) return;
        final persistentImageUrl = materialized.url;
        final imageBytes = materialized.bytes;
        final imageFilePath = imageBytes == null
            ? null
            : await _writeGeneratedImageFile(imageBytes, runId);
        if (!_isActiveGeneration(runId)) return;
        setState(() {
          _generatedImageUrl = persistentImageUrl;
          _generatedImageBytes = imageBytes;
          _generatedImageFilePath = imageFilePath;
        });
      } else {
        setState(() {
          _generationError = '图片生成失败，请检查 API Key 和网络连接';
        });
      }
    } on TimeoutException {
      if (!_isActiveGeneration(runId)) return;
      setState(() {
        _generationError = '生成超时：300 秒内没有返回图片，请检查 GRS AI 任务状态或稍后重试';
      });
    } on DioException catch (e) {
      if (!_isActiveGeneration(runId)) return;
      setState(() {
        _generationError = _formatNetworkError('图片生成', e);
      });
    } catch (e) {
      if (!_isActiveGeneration(runId)) return;
      setState(() {
        _generationError = '生成失败: $e';
      });
    } finally {
      if (_isActiveGeneration(runId)) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _showMusicGenerateDialog(BuildContext context) async {
    final request = await showDialog<_MusicGenerationRequest>(
      context: context,
      builder: (_) => const _MusicGenerationDialog(),
    );

    final musicRequest = request;
    if (!mounted || musicRequest == null || musicRequest.prompt.isEmpty) {
      return;
    }
    await _generateMusic(
      musicRequest.prompt,
      lyrics: musicRequest.lyrics,
      instrumental: musicRequest.instrumental,
    );
  }

  Future<void> _generateMusic(
    String prompt, {
    String? lyrics,
    bool instrumental = true,
  }) async {
    if (prompt.isEmpty || _isGenerating) return;
    final runId = ++_generationRunId;

    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final apiKey = await ModelRouter.getApiKey(ModelType.music);
      if (!_isActiveGeneration(runId)) return;
      if (apiKey.isEmpty) {
        setState(() {
          _generationError = '请先在「设置 → API 配置」中配置音乐生成 API Key';
        });
        return;
      }

      final provider = await AiProviderRegistry.forModelType(ModelType.music);
      if (!_isActiveGeneration(runId)) return;
      final musicUrl = await provider
          .generateMusic(
            prompt: prompt,
            apiKey: apiKey,
            lyrics: lyrics,
            instrumental: instrumental,
          )
          .timeout(const Duration(seconds: 240));

      if (!_isActiveGeneration(runId)) return;
      if (musicUrl != null && musicUrl.isNotEmpty) {
        setState(() {
          _generatedMusicUrl = musicUrl;
        });
      } else {
        setState(() {
          _generationError = '音乐生成失败：当前供应商不支持音乐生成，或没有返回音频 URL';
        });
      }
    } on TimeoutException {
      if (!_isActiveGeneration(runId)) return;
      setState(() {
        _generationError = '生成超时：240 秒内没有返回音频，请检查 MiniMax 额度或稍后重试';
      });
    } on DioException catch (e) {
      if (!_isActiveGeneration(runId)) return;
      setState(() {
        _generationError = _formatNetworkError('音乐生成', e);
      });
    } catch (e) {
      if (!_isActiveGeneration(runId)) return;
      setState(() {
        _generationError = '音乐生成失败: $e';
      });
    } finally {
      if (_isActiveGeneration(runId)) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Widget _buildGeneratedImage(BuildContext context, List<ObjectInfo> objects) {
    final imageUrl = _generatedImageUrl!;
    final imageFilePath = _generatedImageFilePath;
    final imageBytes = imageFilePath == null ? _generatedImageBytes : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('AI 生成图片', '点击嵌入到游戏代码中'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageFilePath != null
                ? Image.file(
                    File(imageFilePath),
                    height: 200,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                : imageBytes != null
                ? Image.memory(
                    imageBytes,
                    height: 200,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                : Image.network(
                    imageUrl,
                    height: 200,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
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
              if (objects.isNotEmpty)
                _actionChip(
                  icon: Icons.transform,
                  label: '替换对象',
                  onTap: () => _showApplyImageToObjectDialog(objects),
                ),
              _actionChip(
                icon: Icons.delete_outline,
                label: '清除',
                onTap: () {
                  setState(() {
                    _generatedImageUrl = null;
                    _generatedImageBytes = null;
                    _generatedImageFilePath = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedMusic(BuildContext context) {
    final url = _generatedMusicUrl!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('AI 生成配乐', '点击嵌入到游戏代码中'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.graphic_eq,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '游戏 BGM 已生成',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        url,
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                onTap: () => _embedMusicInCode(),
              ),
              _actionChip(
                icon: Icons.delete_outline,
                label: '清除',
                onTap: () => setState(() => _generatedMusicUrl = null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _embedImageInCode() {
    if (_generatedImageUrl == null) return;
    final html = widget.htmlCode;
    final imageUrl = jsonEncode(_generatedImageUrl);

    final imageLoader =
        '''
<script>
// AI-generated game asset
const aiGeneratedImage = new Image();
aiGeneratedImage.src = $imageUrl;
</script>
''';

    final updated = _injectSnippet(html, imageLoader);
    _applyUpdatedCode(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('图片已嵌入游戏代码，可通过 aiGeneratedImage 引用'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Uint8List? _decodeDataImage(String imageUrl) {
    if (!imageUrl.startsWith('data:image')) return null;

    final commaIndex = imageUrl.indexOf(',');
    if (commaIndex < 0 || commaIndex == imageUrl.length - 1) return null;

    try {
      return base64Decode(imageUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Future<_MaterializedImageAsset> _materializeImageAsset(
    String imageUrl,
    int runId,
  ) async {
    final dataBytes = _decodeDataImage(imageUrl);
    if (dataBytes != null) {
      return _MaterializedImageAsset(url: imageUrl, bytes: dataBytes);
    }

    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return _MaterializedImageAsset(url: imageUrl);
    }

    try {
      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (!_isActiveGeneration(runId)) {
        return _MaterializedImageAsset(url: imageUrl);
      }
      final bytes = Uint8List.fromList(response.data ?? const <int>[]);
      if (bytes.isEmpty) return _MaterializedImageAsset(url: imageUrl);
      final mimeType = _imageMimeType(response.headers.value('content-type'));
      return _MaterializedImageAsset(
        url: 'data:$mimeType;base64,${base64Encode(bytes)}',
        bytes: bytes,
      );
    } catch (_) {
      return _MaterializedImageAsset(url: imageUrl);
    }
  }

  String _imageMimeType(String? contentType) {
    final normalized = contentType?.split(';').first.trim().toLowerCase();
    if (normalized != null && normalized.startsWith('image/')) {
      return normalized;
    }
    return 'image/png';
  }

  Future<String?> _writeGeneratedImageFile(Uint8List bytes, int runId) async {
    try {
      final dir = await getTemporaryDirectory();
      if (!_isActiveGeneration(runId)) return null;
      final file = File(
        '${dir.path}/gameforge_generated_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showApplyImageToObjectDialog(List<ObjectInfo> objects) async {
    if (_generatedImageUrl == null) return;

    final selected = await showDialog<ObjectInfo>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Row(
          children: [
            Icon(Icons.transform, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '替换游戏对象',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.48,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: objects
                  .map(
                    (object) => ListTile(
                      dense: true,
                      leading: Icon(
                        object.icon,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      title: Text(
                        object.name,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      subtitle: Text(
                        '用当前生成图片覆盖 ${object.name} 的绘制',
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, object),
                    ),
                  )
                  .toList(),
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
        ],
      ),
    );

    if (!mounted || selected == null) return;
    _applyImageToObject(selected);
  }

  void _applyImageToObject(ObjectInfo object) {
    if (_generatedImageUrl == null) return;

    final html = widget.htmlCode;
    final assetKey = _assetKeyForObject(object.name);
    var updated = _injectSnippet(html, _buildObjectAssetScript(assetKey));
    var patched = false;

    for (final fn in _drawFunctionNamesForAsset(assetKey)) {
      final result = _wrapDrawFunction(updated, fn, assetKey);
      if (result != updated) patched = true;
      updated = result;
    }

    if (!patched) {
      final overlayed = _appendObjectOverlayToDraw(updated, assetKey);
      if (overlayed != updated) patched = true;
      updated = overlayed;
    }

    if (!patched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('没有找到 ${object.name} 的绘制入口，无法自动替换'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    _applyUpdatedCode(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${object.name} 已替换为当前生成图片'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _buildObjectAssetScript(String assetKey) {
    final imageUrl = jsonEncode(_generatedImageUrl);
    final key = jsonEncode(assetKey);

    return '''
<script>
// GameForger generated object asset
window.__gfAssetImages = window.__gfAssetImages || {};
(function(){
  const img = new Image();
  img.crossOrigin = 'anonymous';
  img.src = $imageUrl;
  window.__gfAssetImages[$key] = img;
})();
window.__gfDrawAsset = window.__gfDrawAsset || function(key, entity) {
  const img = window.__gfAssetImages && window.__gfAssetImages[key];
  if (!img || !img.complete || !entity) return false;
  const radius = Number(entity.r ?? entity.radius ?? 16);
  const radial = entity.r != null || entity.radius != null;
  const explicitSize = entity.w != null || entity.width != null || entity.h != null || entity.height != null;
  let x = Number(entity.x ?? entity.cx ?? entity.left ?? 0);
  let y = Number(entity.y ?? entity.cy ?? entity.top ?? 0);
  const w = Number(entity.w ?? entity.width ?? radius * 2);
  const h = Number(entity.h ?? entity.height ?? radius * 2);
  if (!isFinite(x) || !isFinite(y) || !isFinite(w) || !isFinite(h)) return false;
  if (radial && !explicitSize) { x -= w / 2; y -= h / 2; }
  ctx.save();
  if (key === 'player' && entity.facingRight === false) {
    ctx.translate(x + w, y);
    ctx.scale(-1, 1);
    ctx.drawImage(img, 0, 0, w, h);
  } else {
    ctx.drawImage(img, x, y, w, h);
  }
  ctx.restore();
  return true;
};
window.__gfDrawAssetCollection = window.__gfDrawAssetCollection || function(key, items) {
  if (!items) return false;
  let drawn = false;
  for (const item of items) {
    if (item && item.g) continue;
    drawn = window.__gfDrawAsset(key, item) || drawn;
  }
  return drawn;
};
</script>
''';
  }

  String _wrapDrawFunction(String html, String functionName, String assetKey) {
    final originalName = '${functionName}__gfOriginal';
    if (html.contains('function $originalName(')) return html;

    final start = html.indexOf('function $functionName(');
    if (start < 0) return html;

    final paramsStart = html.indexOf('(', start);
    final paramsEnd = _findMatchingChar(html, paramsStart, '(', ')');
    if (paramsStart < 0 || paramsEnd < 0) return html;

    final bodyStart = html.indexOf('{', paramsEnd);
    final bodyEnd = _findMatchingChar(html, bodyStart, '{', '}');
    if (bodyStart < 0 || bodyEnd < 0) return html;

    final params = html.substring(paramsStart + 1, paramsEnd).trim();
    final originalDecl = html
        .substring(start, bodyStart)
        .replaceFirst('function $functionName', 'function $originalName');
    final originalBody = html.substring(bodyStart, bodyEnd + 1);
    final entityExpression = _entityExpressionForWrapper(assetKey, params);

    final wrapper =
        '''
$originalDecl$originalBody
function $functionName($params) {
  if (window.__gfDrawAsset && window.__gfDrawAsset(${jsonEncode(assetKey)}, $entityExpression)) return;
  return $originalName($params);
}
''';

    return html.replaceRange(start, bodyEnd + 1, wrapper);
  }

  String _appendObjectOverlayToDraw(String html, String assetKey) {
    const functionName = 'draw';
    if (html.contains('GameForger fallback object overlay: $assetKey')) {
      return html;
    }

    final start = html.indexOf('function $functionName(');
    if (start < 0) return html;

    final bodyStart = html.indexOf('{', start);
    final bodyEnd = _findMatchingChar(html, bodyStart, '{', '}');
    if (bodyStart < 0 || bodyEnd < 0) return html;

    final overlay = _fallbackOverlaySnippet(assetKey);
    if (overlay.isEmpty) return html;

    return html.replaceRange(bodyEnd, bodyEnd, overlay);
  }

  String _fallbackOverlaySnippet(String assetKey) {
    final key = jsonEncode(assetKey);
    switch (assetKey) {
      case 'player':
        return '''
  // GameForger fallback object overlay: player
  if (window.__gfDrawAsset) window.__gfDrawAsset($key, typeof player !== 'undefined' ? player : (typeof p !== 'undefined' ? p : null));
''';
      case 'enemy':
        return '''
  // GameForger fallback object overlay: enemy
  if (window.__gfDrawAssetCollection) window.__gfDrawAssetCollection($key, typeof enemies !== 'undefined' ? enemies : []);
''';
      case 'obstacle':
        return '''
  // GameForger fallback object overlay: obstacle
  if (window.__gfDrawAssetCollection) window.__gfDrawAssetCollection($key, typeof obstacles !== 'undefined' ? obstacles : []);
''';
      case 'coin':
      case 'collectible':
        return '''
  // GameForger fallback object overlay: $assetKey
  if (window.__gfDrawAssetCollection) window.__gfDrawAssetCollection($key, typeof coins !== 'undefined' ? coins : (typeof collectibles !== 'undefined' ? collectibles : (typeof it !== 'undefined' ? it : [])));
''';
      case 'platform':
        return '''
  // GameForger fallback object overlay: platform
  if (window.__gfDrawAssetCollection) window.__gfDrawAssetCollection($key, typeof platforms !== 'undefined' ? platforms : (typeof pl !== 'undefined' ? pl : []));
''';
      default:
        return '';
    }
  }

  int _findMatchingChar(
    String source,
    int openIndex,
    String open,
    String close,
  ) {
    if (openIndex < 0 || openIndex >= source.length) return -1;
    var depth = 0;
    var quote = '';
    var escaping = false;

    for (var i = openIndex; i < source.length; i++) {
      final char = source[i];

      if (quote.isNotEmpty) {
        if (escaping) {
          escaping = false;
        } else if (char == '\\') {
          escaping = true;
        } else if (char == quote) {
          quote = '';
        }
        continue;
      }

      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        continue;
      }

      if (char == open) depth++;
      if (char == close) {
        depth--;
        if (depth == 0) return i;
      }
    }

    return -1;
  }

  String _assetKeyForObject(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('player')) return 'player';
    if (lower.contains('enemy') || lower.contains('boss')) return 'enemy';
    if (lower.contains('obstacle')) return 'obstacle';
    if (lower.contains('platform') || lower.contains('ground')) {
      return 'platform';
    }
    if (lower.contains('coin') || lower.contains('star')) return 'coin';
    if (lower.contains('collectible') ||
        lower.contains('item') ||
        lower.contains('heart') ||
        lower.contains('goal') ||
        lower.contains('portal')) {
      return 'collectible';
    }
    if (lower.contains('bullet')) return 'bullet';
    if (lower.contains('powerup')) return 'powerup';
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  List<String> _drawFunctionNamesForAsset(String assetKey) {
    switch (assetKey) {
      case 'player':
        return ['drawPlayer'];
      case 'enemy':
        return ['drawEnemy'];
      case 'obstacle':
        return ['drawObstacle'];
      case 'platform':
        return ['drawPlatform'];
      case 'coin':
        return ['drawCoin', 'drawCollectible'];
      case 'collectible':
        return ['drawCollectible', 'drawCoin', 'drawPowerup'];
      case 'bullet':
        return ['drawBullet'];
      case 'powerup':
        return ['drawPowerup'];
      default:
        return [];
    }
  }

  String _entityExpressionForWrapper(String assetKey, String params) {
    final paramNames = params
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (paramNames.isNotEmpty) return paramNames.first;

    switch (assetKey) {
      case 'player':
        return "typeof player !== 'undefined' ? player : (typeof p !== 'undefined' ? p : null)";
      default:
        return 'null';
    }
  }

  void _embedMusicInCode() {
    if (_generatedMusicUrl == null) return;
    final html = widget.htmlCode;
    final musicUrl = jsonEncode(_generatedMusicUrl);

    final musicLoader =
        '''
<script>
// AI-generated game BGM
const aiGeneratedMusic = new Audio($musicUrl);
aiGeneratedMusic.loop = true;
aiGeneratedMusic.volume = 0.35;
function playAIGeneratedMusic() {
  aiGeneratedMusic.play().catch(() => {});
}
window.addEventListener('pointerdown', playAIGeneratedMusic, { once: true });
window.addEventListener('keydown', playAIGeneratedMusic, { once: true });
</script>
''';

    final updated = _injectSnippet(html, musicLoader);
    _applyUpdatedCode(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('配乐已嵌入游戏代码，首次点击或按键后自动播放'),
        backgroundColor: AppTheme.secondary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _injectSnippet(String html, String snippet) {
    final lower = html.toLowerCase();
    final headIndex = lower.indexOf('</head>');
    if (headIndex >= 0) {
      return html.replaceRange(headIndex, headIndex, snippet);
    }

    final bodyIndex = lower.indexOf('</body>');
    if (bodyIndex >= 0) {
      return html.replaceRange(bodyIndex, bodyIndex, snippet);
    }

    return '$html\n$snippet';
  }

  String _formatNetworkError(String action, DioException error) {
    final connectSeconds = error.requestOptions.connectTimeout?.inSeconds;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '$action连接超时：${connectSeconds ?? 90} 秒内没有连上模型服务，请检查网络、代理或稍后重试。';
      case DioExceptionType.receiveTimeout:
        return '$action响应超时：模型服务已连接但没有及时返回结果，请稍后重试。';
      case DioExceptionType.sendTimeout:
        return '$action请求发送超时：请检查网络连接后重试。';
      case DioExceptionType.connectionError:
        return '$action网络连接失败：请检查网络、代理或模型服务可用性。';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final data = error.response?.data;
        final detail = data is Map && data['error'] != null
            ? '，${data['error']}'
            : '';
        return '$action失败：模型服务返回 ${status ?? '未知状态'}$detail。';
      case DioExceptionType.cancel:
        return '$action已取消。';
      case DioExceptionType.badCertificate:
        return '$action失败：证书验证失败，请检查网络环境。';
      case DioExceptionType.unknown:
        return '$action失败：${error.message ?? '未知网络错误'}';
    }
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
    void addObject(String name, IconData icon) {
      if (!objects.any((o) => o.name == name) && objects.length < 12) {
        objects.add(ObjectInfo(name: name, icon: icon));
      }
    }

    for (final entry in objectPatterns.entries) {
      if (html.contains(entry.key)) {
        final name = entry.key[0].toUpperCase() + entry.key.substring(1);
        addObject(name, entry.value);
      }
      if (objects.length >= 12) break;
    }

    if (RegExp(r'\b(?:const|let|var)\s+p\s*=\s*\{').hasMatch(html)) {
      addObject('Player', Icons.person);
    }
    if (RegExp(r'\bpl\s*=').hasMatch(html)) {
      addObject('Platform', Icons.landscape);
    }
    if (RegExp(r'\bit\s*=').hasMatch(html)) {
      addObject('Collectible', Icons.diamond);
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

class _MusicGenerationRequest {
  final String prompt;
  final String? lyrics;
  final bool instrumental;

  const _MusicGenerationRequest({
    required this.prompt,
    required this.lyrics,
    required this.instrumental,
  });
}

class _MaterializedImageAsset {
  final String url;
  final Uint8List? bytes;

  const _MaterializedImageAsset({required this.url, this.bytes});
}

class _MusicGenerationDialog extends StatefulWidget {
  const _MusicGenerationDialog();

  @override
  State<_MusicGenerationDialog> createState() => _MusicGenerationDialogState();
}

class _MusicGenerationDialogState extends State<_MusicGenerationDialog> {
  final _promptController = TextEditingController();
  final _lyricsController = TextEditingController();
  bool _instrumental = true;

  @override
  void dispose() {
    _promptController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceVariant,
      title: const Row(
        children: [
          Icon(Icons.music_note, color: AppTheme.secondary, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI 生成游戏配乐',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '描述游戏场景、节奏、情绪和乐器。默认使用 MiniMax 生成可嵌入游戏的音频 URL。',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: '例如：冷静的科幻 Roguelike 主菜单 BGM，低频脉冲，玻璃合成器，中速循环',
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
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _instrumental,
                onChanged: (value) => setState(() => _instrumental = value),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '纯音乐',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                subtitle: const Text(
                  '游戏 BGM 推荐开启；关闭后可输入歌词',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                ),
              ),
              if (!_instrumental) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _lyricsController,
                  maxLines: 6,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: '[Verse]\\n星尘落在黑色引擎\\n[Chorus]\\n我们穿过新的轨迹',
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '取消',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(
              context,
              _MusicGenerationRequest(
                prompt: _promptController.text.trim(),
                lyrics: _lyricsController.text.trim(),
                instrumental: _instrumental,
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.black,
          ),
          child: const Text('开始生成'),
        ),
      ],
    );
  }
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
