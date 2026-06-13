import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
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
        title: Text('修改用户名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: '输入新用户名'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('保存'),
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
    final themeMode = ref.watch(themeControllerProvider);
    final email = authState.user?.email ?? '未知';
    final displayName = _username.isNotEmpty ? _username : email;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
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
          const ForgeSectionLabel(title: 'Configuration'),
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
                icon: themeMode.isLight
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                accent: AppTheme.primary,
                title: '外观',
                subtitle: themeMode.label,
                badge: ForgeChip(
                  label: themeMode.isLight ? 'Light' : 'Dark',
                  tone: ForgeChipTone.online,
                ),
                onTap: () =>
                    ref.read(themeControllerProvider.notifier).toggle(),
              ),
              _ActionGlassTile(
                icon: Icons.monetization_on_rounded,
                accent: AppTheme.gold,
                title: '点数中心',
                subtitle: '查看余额、购买点数',
                badge: ForgeChip(label: '点数', tone: ForgeChipTone.gold),
                onTap: () => context.push('/settings/credits'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ForgeSectionLabel(title: 'System'),
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
          Text(
            'GAMEFORGER · WORKSHOP 1.4',
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
        title: Text('退出登录'),
        content: Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('退出'),
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
        Text(
          'GameForger 是一款基于 AI 的游戏生成助手。'
          '通过对话式引导，帮助你从故事、美术到玩法，'
          '将创意转化为可运行的 HTML5 小游戏。',
        ),
      ],
    );
  }

  void _showSettingsMenu() {
    final authState = ref.read(authProvider);
    final themeMode = ref.read(themeControllerProvider);
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
                      child: Icon(
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
                            style: TextStyle(
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
                leading: Icon(Icons.edit_rounded),
                title: Text('修改用户名'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editUsername();
                },
              ),
              ListTile(
                leading: Icon(Icons.sync_rounded),
                title: Text('刷新账号信息'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _loadingProfile = true);
                  _loadProfile();
                },
              ),
              ListTile(
                leading: Icon(
                  themeMode.isLight
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                title: Text(themeMode.nextLabel),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(themeControllerProvider.notifier).toggle();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ForgeAppMark(size: 24),
            const Spacer(),
            ForgeIconButton(
              icon: Icons.more_horiz_rounded,
              onTap: onMore,
              tooltip: '更多',
              size: 36,
              iconSize: 16,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'WORKSHOP // PROFILE',
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text('Profile.', style: Theme.of(context).textTheme.headlineLarge),
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
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppTheme.textPrimary.withValues(alpha: 0.2),
                    width: 0.7,
                  ),
                ),
                child: Text(
                  initial.toLowerCase(),
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 28,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
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
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(
            color: AppTheme.textPrimary.withValues(alpha: 0.12),
            height: 1,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ControlMetric(
                  label: 'CREDITS',
                  value: '1,240',
                  gold: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ControlMetric(label: 'SHIPPED', value: '08'),
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
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: gold ? AppTheme.gold : AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            fontFamily: 'Georgia',
            height: 1,
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.textPrimary.withValues(alpha: 0.2),
            width: 0.6,
          ),
          bottom: BorderSide(
            color: AppTheme.textPrimary.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
      ),
      child: Column(
        children: List.generate(children.length, (index) => children[index]),
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
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.textPrimary.withValues(alpha: 0.08),
              width: 0.6,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive
                          ? AppTheme.error
                          : AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[const SizedBox(width: 8), badge!],
            const SizedBox(width: 8),
            if (!destructive)
              Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
