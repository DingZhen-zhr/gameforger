import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/preview_provider.dart';

class CodePanel extends ConsumerStatefulWidget {
  final String projectId;
  final ValueChanged<String>? onApplyCode;

  const CodePanel({
    super.key,
    required this.projectId,
    this.onApplyCode,
  });

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
      color: const Color(0xFF0D1117),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          const Icon(Icons.code, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            'index.html',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const Spacer(),
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
            GestureDetector(
              onTap: () => _copyCode(context, code),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.outlineDark),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '复制',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                ),
              ),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: primary ? AppTheme.primary : null,
          border: Border.all(
            color: primary ? AppTheme.primary : AppTheme.outlineDark,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}
