import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../services/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _username = '';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await SupabaseManager.client
          .from('profiles')
          .select('username')
          .single();
      if (mounted) {
        setState(() {
          _username = response['username'] as String? ?? '';
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _editUsername() async {
    final ctrl = TextEditingController(text: _username);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改用户名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新用户名'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == _username) return;
    try {
      await SupabaseManager.client
          .from('profiles')
          .update({'username': result})
          .eq('id', ref.read(authProvider).user!.id);
      if (mounted) {
        setState(() => _username = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final email = authState.user?.email ?? '未知';
    final displayName = _username.isNotEmpty ? _username : email;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 118),
        children: [
          _SettingsHero(
            displayName: displayName,
            email: email,
            username: _username,
            loading: _loadingProfile,
            onEdit: _editUsername,
          ),
          const SizedBox(height: 18),
          const GlassSectionHeader(title: '常用', subtitle: '把配置入口放在最前面，减少来回切换。'),
          const SizedBox(height: 12),
          _ActionGlassTile(
            icon: Icons.key_rounded,
            accent: AppTheme.tabSettings,
            title: 'API 配置',
            subtitle: '配置各模型 API Key',
            onTap: () => context.push('/settings/api'),
          ),
          const SizedBox(height: 10),
          _ActionGlassTile(
            icon: Icons.monetization_on_rounded,
            accent: AppTheme.warmAccent,
            title: '点数中心',
            subtitle: '查看余额、购买点数',
            onTap: () => context.push('/settings/credits'),
          ),
          const SizedBox(height: 18),
          const GlassSectionHeader(title: '系统', subtitle: '项目说明、版本信息和退出入口。'),
          const SizedBox(height: 12),
          _ActionGlassTile(
            icon: Icons.info_outline_rounded,
            accent: AppTheme.tabProject,
            title: '关于 GameForger',
            subtitle: '使用说明、版本信息',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 10),
          LiquidGlassSurface(
            borderRadius: BorderRadius.circular(24),
            tintColor: AppTheme.error,
            tintOpacity: 0.08,
            borderOpacity: 0.16,
            padding: const EdgeInsets.all(14),
            child: TextButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
              label: const Text(
                '退出登录',
                style: TextStyle(color: AppTheme.error),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                foregroundColor: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'GameForger',
      applicationVersion: '1.0.0',
      applicationLegalese: 'GameForger AI - 让你的游戏创意变成现实',
      children: [
        const Text(
          'GameForger 是一款基于 AI 的游戏生成助手。'
          '通过对话式引导，帮助你从故事、美术到玩法，'
          '将创意转化为可运行的 HTML5 小游戏。',
        ),
      ],
    );
  }
}

class _SettingsHero extends StatelessWidget {
  final String displayName;
  final String email;
  final String username;
  final bool loading;
  final VoidCallback onEdit;

  const _SettingsHero({
    required this.displayName,
    required this.email,
    required this.username,
    required this.loading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(32),
      blurSigma: 28,
      tintColor: AppTheme.tabSettings,
      tintOpacity: 0.11,
      borderOpacity: 0.2,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.tabSettings.withValues(alpha: 0.18),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.tabSettings,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.tabSettings.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AppTheme.tabSettings,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatusChip(
                label: loading ? '同步中' : '已登录',
                icon: loading ? Icons.sync_rounded : Icons.verified_rounded,
                accent: AppTheme.tabSettings,
              ),
              const SizedBox(width: 10),
              _StatusChip(
                label: username.isEmpty ? '未设置用户名' : '用户名已设置',
                icon: Icons.badge_rounded,
                accent: AppTheme.warmAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionGlassTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionGlassTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassSurface(
        borderRadius: BorderRadius.circular(24),
        tintColor: accent,
        tintOpacity: 0.1,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
