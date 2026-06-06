import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../gallery/presentation/gallery_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../providers/home_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentTab = 0;

  static const _tabs = [
    GlassTabItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: '项目',
      accent: AppTheme.tabProject,
    ),
    GlassTabItem(
      icon: Icons.play_circle_outline_rounded,
      selectedIcon: Icons.play_circle_fill_rounded,
      label: '作品',
      accent: AppTheme.tabGallery,
    ),
    GlassTabItem(
      icon: Icons.tune_rounded,
      selectedIcon: Icons.tune_rounded,
      label: '控制',
      accent: AppTheme.tabSettings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadProjects();
    });
  }

  void _showNewProjectDialog() {
    final ctrl = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('新建项目'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            autofocus: true,
            placeholder: '输入项目名称',
            textCapitalization: TextCapitalization.words,
            clearButtonMode: OverlayVisibilityMode.editing,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final title = ctrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              final project = await ref
                  .read(homeProvider.notifier)
                  .createProject(title);
              if (project != null && mounted) {
                context.push('/project/${project.id}/workspace');
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const CosmicBackground(child: SizedBox.expand()),
          Positioned.fill(
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildProjectsTab(homeState),
                const GalleryPage(),
                const SettingsPage(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingGlassTabBar(
              currentIndex: _currentTab,
              onChanged: (i) => setState(() => _currentTab = i),
              items: _tabs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(HomeState homeState) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).loadProjects(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _ProjectsNav(
                  onRefresh: () =>
                      ref.read(homeProvider.notifier).loadProjects(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(child: _buildProjectHero(homeState)),
            ),
            if (homeState.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator(radius: 12)),
              )
            else if (homeState.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ProjectErrorState(
                  message: homeState.error!,
                  onRetry: () => ref.read(homeProvider.notifier).loadProjects(),
                ),
              )
            else if (homeState.projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ProjectEmptyState(onCreate: _showNewProjectDialog),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: ForgeSectionLabel(title: '最近项目', trailing: '按更新时间'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final project = homeState.projects[i];
                    return _SwipeableProjectTile(
                      project: project,
                      onTap: () =>
                          context.push('/project/${project.id}/workspace'),
                      onDelete: () => _confirmDelete(project.id, project.title),
                      onRename: (title) => ref
                          .read(homeProvider.notifier)
                          .renameProject(project.id, title),
                    );
                  }, childCount: homeState.projects.length),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHero(HomeState homeState) {
    final total = homeState.projects.length;
    final drafts = homeState.projects.where((p) => p.status == 'draft').length;
    final generated = homeState.projects
        .where((p) => p.status == 'generated')
        .length;

    return ForgeGlassCard(
      borderRadius: BorderRadius.circular(24),
      accent: AppTheme.primary,
      accentOpacity: 0.08,
      borderOpacity: 0.12,
      glow: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NebulaOrb(size: 46, spin: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '锻造台已就绪',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ForgeChip(
                          label: homeState.isOffline ? '离线缓存' : '在线',
                          tone: homeState.isOffline
                              ? ForgeChipTone.offline
                              : ForgeChipTone.online,
                          dot: true,
                        ),
                        const ForgeChip(
                          label: '已登录',
                          tone: ForgeChipTone.violet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ForgeIconButton(
                icon: Icons.refresh_rounded,
                accent: AppTheme.primary,
                glow: true,
                onTap: () => ref.read(homeProvider.notifier).loadProjects(),
                tooltip: '刷新',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(value: '$total', label: '总项目'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(value: '$drafts', label: '草稿'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(value: '$generated', label: '已生成'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ForgePrimaryButton(
              label: '新建项目',
              icon: Icons.add_rounded,
              onPressed: _showNewProjectDialog,
              accent: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String title) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除项目'),
        content: Text('确定要删除「$title」吗？\n此操作不可撤销。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(homeProvider.notifier).deleteProject(id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _ProjectsNav extends StatelessWidget {
  final VoidCallback onRefresh;

  const _ProjectsNav({required this.onRefresh});

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
                '项目',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Cosmic Forge 控制台',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ForgeIconButton(icon: Icons.search_rounded, tooltip: '搜索'),
        const SizedBox(width: 8),
        ForgeIconButton(
          icon: Icons.more_horiz_rounded,
          onTap: onRefresh,
          tooltip: '同步',
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ProjectErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProjectErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _ProjectEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _ProjectEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LiquidGlassSurface(
            borderRadius: BorderRadius.circular(26),
            tintColor: AppTheme.tabProject,
            tintOpacity: 0.12,
            padding: const EdgeInsets.all(18),
            child: const Icon(
              Icons.gamepad_outlined,
              size: 38,
              color: AppTheme.tabProject,
            ),
          ),
          const SizedBox(height: 20),
          Text('还没有项目', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            '创建第一个游戏项目，AI 会从玩法、世界观和素材方向逐步补齐。',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: onCreate,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20),
                SizedBox(width: 6),
                Text('创建项目'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A project tile with iOS-style swipe-to-delete.
class _SwipeableProjectTile extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _SwipeableProjectTile({
    required this.project,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(project.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false; // we handle deletion ourselves via the dialog
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppTheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                '删除',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: _ProjectTile(project: project, onTap: onTap, onRename: onRename),
      ),
    );
  }
}

class _ProjectTile extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final ValueChanged<String> onRename;

  const _ProjectTile({
    required this.project,
    required this.onTap,
    required this.onRename,
  });

  @override
  State<_ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<_ProjectTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final daysAgo = DateTime.now().difference(widget.project.updatedAt).inDays;
    final timeStr = daysAgo == 0
        ? '今天'
        : daysAgo == 1
        ? '昨天'
        : '$daysAgo 天前';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () => _showRenameSheet(context),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ForgeGlassCard(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(10),
          accent: AppTheme.primary,
          accentOpacity: 0.04,
          borderOpacity: 0.08,
          child: Row(
            children: [
              NebulaSeed(
                hue: widget.project.title.hashCode,
                accent: widget.project.status == 'generated'
                    ? AppTheme.secondary
                    : AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '更新于 $timeStr',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.project.status == 'draft')
                const ForgeChip(label: '草稿', tone: ForgeChipTone.draft),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: widget.project.title);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('重命名项目'),
        message: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: CupertinoTextField(
            controller: nameCtrl,
            autofocus: true,
            placeholder: '项目名称',
            clearButtonMode: OverlayVisibilityMode.editing,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              final t = nameCtrl.text.trim();
              if (t.isNotEmpty) widget.onRename(t);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }
}
