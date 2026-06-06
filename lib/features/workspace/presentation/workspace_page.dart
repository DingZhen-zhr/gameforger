import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';
import '../../../services/ai/game_gen_service.dart';
import '../../../services/credits/credit_service.dart';
import '../../../services/storage/local_db_service.dart';
import '../../../services/supabase/game_build_service.dart';
import '../../../services/supabase/supabase_client.dart';
import '../../preview/presentation/providers/preview_provider.dart';
import 'providers/workspace_provider.dart';
import 'widgets/game_spec_progress.dart';
import 'widgets/spec_cards_panel.dart';
import 'widgets/card_view.dart';
import '../domain/card_model.dart';
import '../domain/game_spec.dart';

class WorkspacePage extends ConsumerWidget {
  final String projectId;

  const WorkspacePage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider(projectId));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CosmicBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _WorkspaceTopBar(
                title: '创意工作台',
                subtitle:
                    '${state.gameSpec.filledCount} / 9 维度 · ${state.isSpecComplete ? '可生成' : '校准中'}',
                canGenerate: state.isSpecComplete,
                onBack: () => context.pop(),
                onGenerate: () => _generateAndNavigate(
                  context,
                  ref,
                  projectId,
                  state.gameSpec,
                  state.isSpecComplete,
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      sliver: SliverToBoxAdapter(
                        child: GameSpecProgress(
                          spec: state.gameSpec,
                          onTap: () =>
                              _showSpecOverview(context, ref, projectId, state),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SpecCardsPanel(
                        spec: state.gameSpec,
                        filledDimKeys: ref
                            .read(workspaceProvider(projectId).notifier)
                            .filledDimKeys,
                        onEdit: (dimKey, label, currentValue) =>
                            _showEditDialog(
                              context,
                              ref,
                              projectId,
                              dimKey,
                              label,
                              currentValue,
                            ),
                        onRediscuss: (dimKey, label) => _showRediscussConfirm(
                          context,
                          ref,
                          projectId,
                          dimKey,
                          label,
                        ),
                      ),
                    ),
                    if (state.messages.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _ChatBubble(
                              message: state.messages[i],
                              projectId: projectId,
                            ),
                            childCount: state.messages.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),
              const _QuickToolbar(),
              const _InputBar(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndNavigate(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    GameSpec spec,
    bool enabled,
  ) async {
    if (!enabled) return;

    if (!context.mounted) return;

    // Track cancellation state
    bool cancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceVariant,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AI 正在生成游戏...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '设计文档 → 代码生成\n超时限制 3 分钟',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    '取消',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final service = GameGenService();
      final html = await service
          .generateGame(spec)
          .timeout(
            const Duration(minutes: 3),
            onTimeout: () => throw Exception(
              '游戏生成超时（3分钟），请简化游戏设定后重试，或到「设置 → API 配置」配置自定义 API Key。',
            ),
          );

      if (cancelled) return;

      ref.read(pendingGameHtmlProvider(projectId).notifier).state = html;

      // Save to Supabase + local cache (non-blocking: preview even if save fails)
      try {
        final buildService = GameBuildService(SupabaseManager.client);
        await buildService.saveBuild(projectId, html, spec);
        await LocalDbService().cacheBuild(projectId, html, spec);
      } catch (saveError) {
        debugPrint('[Workspace] Failed to save build: $saveError');
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        context.push('/project/$projectId/preview');
      }
    } on DeductException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('点数不足！当前余额: ${e.balance} 点，需要: ${e.required} 点'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (cancelled) return;
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('游戏生成失败: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }
}

class _WorkspaceTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool canGenerate;
  final VoidCallback onBack;
  final VoidCallback onGenerate;

  const _WorkspaceTopBar({
    required this.title,
    required this.subtitle,
    required this.canGenerate,
    required this.onBack,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Row(
        children: [
          ForgeIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: onBack,
            tooltip: '返回',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ForgePrimaryButton(
            label: '生成',
            icon: Icons.auto_awesome_rounded,
            onPressed: canGenerate ? onGenerate : null,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '开始与 AI 对话，逐步完善你的游戏创意',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String projectId;

  const _ChatBubble({required this.message, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primary.withValues(alpha: 0.28)
                  : isSystem
                  ? Colors.white.withValues(alpha: 0.045)
                  : Colors.white.withValues(alpha: 0.055),
              border: Border.all(
                color: isUser
                    ? AppTheme.primary.withValues(alpha: 0.38)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser && !isSystem
                    ? const Radius.circular(4)
                    : null,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                message.isStreaming
                    ? _StreamingText(text: message.content)
                    : Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                if (message.cards.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...message.cards.map((c) => CardViewWidget(card: c)),
                ],
              ],
            ),
          ),
          if (!isUser && !isSystem)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                message.isStreaming ? '输入中...' : _formatTime(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StreamingText extends StatefulWidget {
  final String text;
  const _StreamingText({required this.text});

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.text),
              TextSpan(
                text: '|',
                style: TextStyle(
                  color: AppTheme.primary.withValues(alpha: _controller.value),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        );
      },
    );
  }
}

class _QuickToolbar extends ConsumerWidget {
  const _QuickToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarChip(
              icon: Icons.sports_esports,
              label: '玩法',
              onTap: () => _showAddCardDialog(context, ref, CardType.gameplay),
            ),
            const SizedBox(width: 6),
            _ToolbarChip(
              icon: Icons.menu_book,
              label: '故事',
              onTap: () => _showAddCardDialog(context, ref, CardType.story),
            ),
            const SizedBox(width: 6),
            _ToolbarChip(
              icon: Icons.palette,
              label: '美术',
              onTap: () => _showAddCardDialog(context, ref, CardType.art),
            ),
            const SizedBox(width: 6),
            _ToolbarChip(
              icon: Icons.music_note,
              label: '音乐',
              onTap: () => _showAddCardDialog(context, ref, CardType.music),
            ),
            const SizedBox(width: 6),
            _ToolbarChip(
              icon: Icons.inventory_2,
              label: '素材',
              onTap: () => _showAddCardDialog(context, ref, CardType.asset),
            ),
            const SizedBox(width: 6),
            _ToolbarChip(
              icon: Icons.edit_note,
              label: '笔记',
              onTap: () => _showAddCardDialog(context, ref, CardType.userNote),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref, CardType type) {
    final controller = TextEditingController();
    final projectId = _getProjectId(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('添加${type.label}卡片'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入内容...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(workspaceProvider(projectId).notifier).addManualCard(
                  type,
                  {'content': controller.text.trim()},
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  String _getProjectId(BuildContext context) {
    // Extract projectId from route path
    final location = GoRouterState.of(context).pathParameters['id'] ?? '';
    return location;
  }
}

class _ToolbarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ForgeGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(999),
      accent: AppTheme.secondary,
      accentOpacity: 0.04,
      borderOpacity: 0.1,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showEditDialog(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  String dimKey,
  String label,
  String currentValue,
) {
  final controller = TextEditingController(text: currentValue);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceVariant,
      title: Text(
        '编辑 $label',
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: '输入新的$label...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
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
            if (controller.text.trim().isNotEmpty) {
              ref
                  .read(workspaceProvider(projectId).notifier)
                  .editSpecValue(dimKey, controller.text.trim());
              Navigator.pop(ctx);
            }
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

void _showRediscussConfirm(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  String dimKey,
  String label,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceVariant,
      title: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '重新讨论',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Text(
        '确定要重新讨论「$label」吗？\n\nAI 将会针对这个维度重新提问，之前的设定将被清除。你可以通过对话进一步深化你的想法。',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
            ref
                .read(workspaceProvider(projectId).notifier)
                .rediscussDimension(dimKey, label);
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('开始重新讨论'),
        ),
      ],
    ),
  );
}

void _showSpecOverview(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  WorkspaceState state,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceVariant,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final spec = state.gameSpec;
      final items = [
        (Icons.sports_esports, '玩法类型', spec.genre),
        (Icons.menu_book, '主题/故事', spec.theme),
        (Icons.palette, '美术风格', spec.artStyle),
        (Icons.visibility, '视角', spec.cameraView),
        (Icons.precision_manufacturing, '核心机制', spec.coreMechanic),
        (Icons.fitness_center, '玩家能力', spec.playerAbility),
        (Icons.flag, '目标', spec.goal),
        (Icons.music_note, '音乐氛围', spec.musicVibe),
        (Icons.bar_chart, '难度', spec.difficulty),
      ];

      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '游戏创意总览',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.gameSpec.filledCount} / 9',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final (icon, label, value) = item;
                  final isFilled = value != null && value.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isFilled
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value ?? '（未设定）',
                            style: TextStyle(
                              color: isFilled
                                  ? AppTheme.textPrimary
                                  : AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('关闭'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.outlineDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _InputBar extends ConsumerStatefulWidget {
  const _InputBar();

  @override
  ConsumerState<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<_InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final projectId = _getProjectId();
    ref.read(workspaceProvider(projectId).notifier).sendMessage(text);
  }

  String _getProjectId() {
    return GoRouterState.of(context).pathParameters['id'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(workspaceProvider(_getProjectId())).isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: ForgeGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(22),
              accent: AppTheme.primary,
              accentOpacity: 0.05,
              borderOpacity: 0.16,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13.5,
                ),
                decoration: const InputDecoration(
                  hintText: '告诉锻造台下一步...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ForgeIconButton(
            icon: isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
            onTap: isLoading ? null : _send,
            accent: AppTheme.primary,
            glow: !isLoading,
            tooltip: '发送',
          ),
        ],
      ),
    );
  }
}
