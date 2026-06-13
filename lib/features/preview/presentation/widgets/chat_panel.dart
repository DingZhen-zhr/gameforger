import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/preview_provider.dart';
import 'diff_review_panel.dart';

class PreviewChatPanel extends ConsumerStatefulWidget {
  final String projectId;

  const PreviewChatPanel({super.key, required this.projectId});

  @override
  ConsumerState<PreviewChatPanel> createState() => _PreviewChatPanelState();
}

class _PreviewChatPanelState extends ConsumerState<PreviewChatPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  /// Track previous agent state to detect transitions for auto-scroll.
  AgentState _previousAgentState = AgentState.idle;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(previewProvider(widget.projectId).notifier).sendChatMessage(text);
    Future(() => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// Get display text for the current agent state.
  String _agentStateText(AgentState agentState) {
    switch (agentState) {
      case AgentState.thinking:
        return 'AI 正在分析代码...';
      case AgentState.reviewing:
        return '请审核 AI 的修改';
      case AgentState.applying:
        return '正在应用修改...';
      case AgentState.error:
        return '出错了，请重试';
      case AgentState.idle:
        return '';
    }
  }

  IconData _agentStateIcon(AgentState agentState) {
    switch (agentState) {
      case AgentState.thinking:
        return Icons.auto_awesome;
      case AgentState.reviewing:
        return Icons.rate_review;
      case AgentState.applying:
        return Icons.sync;
      case AgentState.error:
        return Icons.error_outline;
      case AgentState.idle:
        return Icons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewProvider(widget.projectId));
    final notifier = ref.read(previewProvider(widget.projectId).notifier);

    // Auto-scroll when entering reviewing state
    if (state.agentState == AgentState.reviewing &&
        _previousAgentState != AgentState.reviewing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _previousAgentState = state.agentState;

    return Container(
      color: AppTheme.bgDark,
      child: Column(
        children: [
          Expanded(
            child: state.chatMessages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: state.chatMessages.length,
                    itemBuilder: (_, i) {
                      final msg = state.chatMessages[i];
                      final isLastAi =
                          !msg.isUser && i == state.chatMessages.length - 1;
                      return _buildBubble(msg, isLastAi, state, notifier);
                    },
                  ),
          ),
          _buildAgentStatusBar(state.agentState),
          _buildInputBar(state),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 36,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '对游戏进行小幅修改',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '例如：把跳跃高度调高、\n把玩家速度加快、改成红色主题',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 18),
            _TransparencyNotice(
              icon: Icons.info_outline,
              title: 'AI 能力边界',
              body: '我可以修改当前 2D HTML5 Canvas 游戏；不支持 3D、多人联网、后端服务、真实支付或外部服务器逻辑。',
            ),
            const SizedBox(height: 8),
            _TransparencyNotice(
              icon: Icons.fact_check_outlined,
              title: '请验证生成结果',
              body: 'AI 可能误解需求或生成不可玩逻辑，请通过预览、试玩和差异审核确认修改是否正确。',
              accent: AppTheme.gold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    PreviewChatMessage msg,
    bool isLastAi,
    PreviewState state,
    PreviewNotifier notifier,
  ) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
            ),
            child: msg.isStreaming
                ? _StreamingText(text: msg.content)
                : Text(
                    msg.content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
          ),
          if (!isUser && !msg.isStreaming)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                '${msg.modelLabel == null ? '由 AI 生成' : '由 ${msg.modelLabel} 生成'} · ${_formatTime(DateTime.now())}',
                style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
              ),
            ),

          // DiffReviewPanel: show after the last AI message during reviewing
          if (isLastAi &&
              state.agentState == AgentState.reviewing &&
              state.pendingEdits.isNotEmpty) ...[
            const SizedBox(height: 4),
            DiffReviewPanel(
              edits: state.pendingEdits,
              onAccept: notifier.acceptEdit,
              onReject: notifier.rejectEdit,
              onAcceptAll: notifier.acceptAllEdits,
              onRejectAll: notifier.rejectAllEdits,
              onApply: () => notifier.applyAcceptedEdits(),
              onManualRetry: notifier.manualRetryEdit,
              isApplying: state.agentState == AgentState.applying,
              isAllDecided: state.pendingEdits.every(
                (e) => e.isAccepted || e.isRejected,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentStatusBar(AgentState agentState) {
    if (agentState == AgentState.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppTheme.outlineDark.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          if (agentState == AgentState.applying)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            )
          else
            Icon(
              _agentStateIcon(agentState),
              size: 14,
              color: agentState == AgentState.reviewing
                  ? AppTheme.gold
                  : agentState == AgentState.error
                  ? AppTheme.error
                  : AppTheme.primary,
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _agentStateText(agentState),
              style: TextStyle(
                fontSize: 12,
                color: agentState == AgentState.error
                    ? AppTheme.error
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(PreviewState state) {
    final canInteract = state.agentState == AgentState.idle;
    final isThinking =
        state.agentState == AgentState.thinking ||
        state.agentState == AgentState.applying;

    String hintText;
    if (isThinking) {
      hintText = 'AI 处理中...';
    } else if (state.agentState == AgentState.reviewing) {
      hintText = '请先审核当前修改';
    } else {
      hintText = '输入修改需求...';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.outlineDark.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: canInteract,
              textInputAction: TextInputAction.send,
              onSubmitted: canInteract ? (_) => _send() : null,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: canInteract ? _send : null,
            icon: Icon(
              isThinking ? Icons.hourglass_top : Icons.send_rounded,
              size: 20,
              color: canInteract ? AppTheme.primary : AppTheme.textTertiary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: canInteract
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
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

class _TransparencyNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  const _TransparencyNotice({
    required this.icon,
    required this.title,
    required this.body,
    this.accent = const Color(0xFF4FC9E8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10.8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
            height: 1.4,
          ),
        );
      },
    );
  }
}
