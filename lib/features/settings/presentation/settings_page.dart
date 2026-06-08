import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 118),
        children: [
          _SettingsNav(onMore: _showSettingsMenu),
          const SizedBox(height: 16),
          _SettingsHero(
            displayName: displayName,
            email: email,
            username: _username,
            loading: _loadingProfile,
            onEdit: _editUsername,
          ),
          const SizedBox(height: 22),
          const ForgeSectionLabel(title: '常用'),
          _SettingsGroup(
            children: [
              _ActionGlassTile(
                icon: Icons.key_rounded,
                accent: AppTheme.primary,
                title: 'API 配置',
                subtitle: '配置各模型 API Key',
                onTap: () => context.push('/settings/api'),
              ),
              _ActionGlassTile(
                icon: Icons.monetization_on_rounded,
                accent: AppTheme.gold,
                title: '点数中心',
                subtitle: '查看余额、购买点数',
                badge: const ForgeChip(label: '点数', tone: ForgeChipTone.gold),
                onTap: () => context.push('/settings/credits'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ForgeSectionLabel(title: '系统'),
          _SettingsGroup(
            children: [
              _ActionGlassTile(
                icon: Icons.info_outline_rounded,
                accent: AppTheme.secondary,
                title: '关于 GameForger',
                subtitle: '使用说明、版本信息',
                onTap: () => _showAbout(context),
              ),
              _ActionGlassTile(
                icon: Icons.logout_rounded,
                accent: AppTheme.error,
                title: '退出登录',
                subtitle: '结束当前账号会话',
                destructive: true,
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'GameForger 1.4',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
              letterSpacing: 0.5,
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

  void _showSettingsMenu() {
    final authState = ref.read(authProvider);
    final email = authState.user?.email ?? '未知';
    final displayName = _username.isNotEmpty ? _username : email;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('修改用户名'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editUsername();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: const Text('刷新账号信息'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _loadingProfile = true);
                  _loadProfile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNav extends StatelessWidget {
  final VoidCallback onMore;

  const _SettingsNav({required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '控制',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '账号与设置',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ForgeIconButton(
          icon: Icons.more_horiz_rounded,
          onTap: onMore,
          tooltip: '更多',
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

    return ForgeGlassCard(
      borderRadius: BorderRadius.circular(24),
      accent: AppTheme.primary,
      accentOpacity: 0.08,
      borderOpacity: 0.12,
      glow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.35),
                    colors: [
                      AppTheme.cyan,
                      AppTheme.primary,
                      AppTheme.primaryContainer,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
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
                        ForgeIconButton(
                          icon: Icons.edit_rounded,
                          size: 34,
                          iconSize: 15,
                          onTap: onEdit,
                          tooltip: '编辑用户名',
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
              ForgeChip(
                label: loading ? '同步中' : '已登录',
                icon: loading ? Icons.sync_rounded : Icons.verified_rounded,
                tone: ForgeChipTone.online,
                dot: !loading,
              ),
              const SizedBox(width: 10),
              ForgeChip(
                label: username.isEmpty ? '未设置用户名' : '用户名已设置',
                icon: Icons.badge_rounded,
                tone: username.isEmpty
                    ? ForgeChipTone.draft
                    : ForgeChipTone.gold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _ControlMetric(label: '剩余点数', value: '查看余额', gold: true),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ControlMetric(label: '模型配置', value: '4 项'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _ControlMetric({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: gold ? AppTheme.gold : AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return ForgeGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(18),
      accent: AppTheme.primary,
      accentOpacity: 0.035,
      borderOpacity: 0.08,
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],
              if (index != children.length - 1)
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            ],
          );
        }),
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
  final Widget? badge;
  final bool destructive;

  const _ActionGlassTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: destructive
                          ? AppTheme.error
                          : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
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
            if (badge != null) ...[const SizedBox(width: 8), badge!],
            const SizedBox(width: 8),
            if (!destructive)
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
