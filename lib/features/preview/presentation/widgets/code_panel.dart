import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_forge.dart';
import '../providers/preview_provider.dart';

class CodePanel extends ConsumerStatefulWidget {
  final String projectId;
  final ValueChanged<String>? onApplyCode;

  const CodePanel({super.key, required this.projectId, this.onApplyCode});

  @override
  ConsumerState<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends ConsumerState<CodePanel> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewProvider(widget.projectId));

    return Container(
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state.htmlCode),
          Expanded(
            child: _isEditing
                ? _buildEditor(state.htmlCode)
                : _buildReadOnly(state.htmlCode),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'index.html',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isEditing) ...[
            _HeaderButton(
              label: '取消',
              onTap: () => setState(() => _isEditing = false),
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              label: '应用',
              onTap: () => _applyEdit(code),
              primary: true,
            ),
          ] else ...[
            _HeaderButton(label: '复制', onTap: () => _copyCode(context, code)),
            const SizedBox(width: 8),
            _HeaderButton(
              label: '编辑',
              onTap: () {
                _editController.text = code;
                setState(() => _isEditing = true);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnly(String code) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(String code) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _editController,
        maxLines: null,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppTheme.textPrimary,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  void _applyEdit(String originalCode) {
    final newCode = _editController.text.trim();
    if (newCode.isNotEmpty && newCode != originalCode) {
      widget.onApplyCode?.call(newCode);
    }
    setState(() => _isEditing = false);
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('代码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _HeaderButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ForgePrimaryButton(
        label: label,
        icon: Icons.check_rounded,
        onPressed: onTap,
        compact: true,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
