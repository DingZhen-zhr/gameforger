import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/preview_provider.dart';

/// Displays proposed code edits as diff cards with accept/reject controls.
class DiffReviewPanel extends StatelessWidget {
  final List<PreviewEditProposal> edits;
  final void Function(String editId) onAccept;
  final void Function(String editId) onReject;
  final VoidCallback onAcceptAll;
  final VoidCallback onRejectAll;
  final VoidCallback onApply;
  final void Function(String editId, String newOld, String newNew)?
  onManualRetry;
  final bool isApplying;
  final bool isAllDecided;

  const DiffReviewPanel({
    super.key,
    required this.edits,
    required this.onAccept,
    required this.onReject,
    required this.onAcceptAll,
    required this.onRejectAll,
    required this.onApply,
    this.onManualRetry,
    this.isApplying = false,
    this.isAllDecided = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, top: 4, bottom: 8, right: 4),
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: AppTheme.primary),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'AI 提议的修改',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...edits.map(
          (edit) => _EditCard(
            edit: edit,
            onAccept: () => onAccept(edit.id),
            onReject: () => onReject(edit.id),
            onManualRetry: onManualRetry,
          ),
        ),
        const SizedBox(height: 8),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final hasPending = edits.any((e) => !e.isAccepted && !e.isRejected);
    final hasAccepted = edits.any((e) => e.isAccepted && !e.isApplied);
    final anyApplied = edits.any((e) => e.isApplied);

    return Column(
      children: [
        // Accept All / Reject All (only when there are pending edits)
        if (edits.length > 1 && hasPending)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    label: '全部接受',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.primary,
                    onTap: onAcceptAll,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    label: '全部拒绝',
                    icon: Icons.cancel_outlined,
                    color: AppTheme.textSecondary,
                    onTap: onRejectAll,
                  ),
                ),
              ],
            ),
          ),
        // Apply button
        if (hasAccepted || anyApplied)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isApplying ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isApplying
                    ? '正在应用修改...'
                    : anyApplied
                    ? '已完成，继续对话'
                    : '应用已接受的修改 (${edits.where((e) => e.isAccepted && !e.isApplied).length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EditCard extends StatelessWidget {
  final PreviewEditProposal edit;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final void Function(String editId, String newOld, String newNew)?
  onManualRetry;

  const _EditCard({
    required this.edit,
    required this.onAccept,
    required this.onReject,
    this.onManualRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDecided = edit.isAccepted || edit.isRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: edit.applyError != null
              ? AppTheme.error.withValues(alpha: 0.5)
              : edit.isApplied
              ? Colors.green.withValues(alpha: 0.4)
              : AppTheme.outlineDark.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(
                  edit.isApplied
                      ? Icons.check_circle
                      : edit.isAccepted
                      ? Icons.check_circle_outline
                      : edit.isRejected
                      ? Icons.cancel_outlined
                      : Icons.code,
                  size: 16,
                  color: edit.isApplied
                      ? Colors.green
                      : edit.isAccepted
                      ? AppTheme.primary
                      : edit.isRejected
                      ? AppTheme.textTertiary
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    edit.applyError != null
                        ? '修改失败'
                        : edit.isApplied
                        ? '已应用'
                        : edit.isAccepted
                        ? '已接受（待应用）'
                        : edit.isRejected
                        ? '已拒绝'
                        : '修改 ${edit.id.replaceAll(RegExp(r'[^0-9]'), '')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: edit.isApplied
                          ? Colors.green
                          : edit.isAccepted
                          ? AppTheme.primary
                          : edit.isRejected
                          ? AppTheme.textTertiary
                          : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (edit.applyError != null) ...[
                  Icon(Icons.error_outline, size: 14, color: AppTheme.error),
                  const SizedBox(width: 4),
                  const Text(
                    '匹配失败',
                    style: TextStyle(fontSize: 11, color: AppTheme.error),
                  ),
                ],
              ],
            ),
          ),

          // Error message
          if (edit.applyError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                edit.applyError!,
                style: const TextStyle(fontSize: 11, color: AppTheme.error),
              ),
            ),

          // Old code
          _CodeBlock(
            label: '旧代码',
            code: edit.oldCode,
            color: Colors.red.withValues(alpha: 0.12),
            borderColor: Colors.red.withValues(alpha: 0.25),
            labelColor: Colors.red,
          ),

          // Arrow between old and new
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_downward,
              size: 16,
              color: AppTheme.textTertiary,
            ),
          ),

          // New code
          _CodeBlock(
            label: '新代码',
            code: edit.newCode,
            color: Colors.green.withValues(alpha: 0.12),
            borderColor: Colors.green.withValues(alpha: 0.25),
            labelColor: Colors.green,
          ),

          // Action buttons
          if (!isDecided && edit.applyError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionChip(
                      label: '接受',
                      icon: Icons.check,
                      color: AppTheme.primary,
                      onTap: onAccept,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionChip(
                      label: '拒绝',
                      icon: Icons.close,
                      color: AppTheme.textSecondary,
                      onTap: onReject,
                    ),
                  ),
                ],
              ),
            ),

          // Retry button for errors
          if (edit.applyError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showManualFixDialog(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('手动修正', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showManualFixDialog(BuildContext context) {
    final oldController = TextEditingController(text: edit.oldCode);
    final newController = TextEditingController(text: edit.newCode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '手动修正代码匹配',
          style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请修正旧代码以精确匹配游戏代码中的内容：',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              const Text(
                '旧代码（匹配目标）：',
                style: TextStyle(fontSize: 12, color: AppTheme.error),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: oldController,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '新代码（替换为）：',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: newController,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onManualRetry?.call(
                edit.id,
                oldController.text,
                newController.text,
              );
            },
            child: const Text(
              '应用修正',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String label;
  final String code;
  final Color color;
  final Color borderColor;
  final Color labelColor;

  const _CodeBlock({
    required this.label,
    required this.code,
    required this.color,
    required this.borderColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
