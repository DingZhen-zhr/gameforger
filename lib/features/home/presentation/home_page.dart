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
  String _projectQuery = '';
  _ProjectSortMode _projectSortMode = _ProjectSortMode.updatedDesc;

  static List<GlassTabItem> get _tabs => [
    GlassTabItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Projects',
      accent: AppTheme.tabProject,
    ),
    GlassTabItem(
      icon: Icons.play_circle_outline_rounded,
      selectedIcon: Icons.play_circle_fill_rounded,
      label: 'Works',
      accent: AppTheme.tabGallery,
    ),
    GlassTabItem(
      icon: Icons.tune_rounded,
      selectedIcon: Icons.tune_rounded,
      label: 'Profile',
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
        title: Text('新建项目'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            autofocus: true,
            placeholder: '输入项目名称',
            textCapitalization: TextCapitalization.words,
            clearButtonMode: OverlayVisibilityMode.editing,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消'),
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
            child: Text('创建'),
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
    final visibleProjects = _filterAndSortProjects(homeState.projects);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).loadProjects(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _ProjectsNav(
                  query: _projectQuery,
                  onSearch: _showProjectSearch,
                  onMore: _showProjectsMenu,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              sliver: SliverToBoxAdapter(child: _buildProjectHero(homeState)),
            ),
            if (homeState.isLoading)
              SliverFillRemaining(
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
            else if (visibleProjects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ProjectSearchEmptyState(
                  query: _projectQuery,
                  onClear: () => setState(() => _projectQuery = ''),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                sliver: SliverToBoxAdapter(
                  child: ForgeSectionLabel(
                    title: _projectQuery.isEmpty ? 'Recent' : 'Search',
                    trailing: _projectQuery.isEmpty
                        ? '↓ $_projectSortLabel'
                        : '${visibleProjects.length} 项匹配',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final project = visibleProjects[i];
                    return _SwipeableProjectTile(
                      project: project,
                      onTap: () =>
                          context.push('/project/${project.id}/workspace'),
                      onDelete: () => _confirmDelete(project.id, project.title),
                      onRename: (title) => ref
                          .read(homeProvider.notifier)
                          .renameProject(project.id, title),
                    );
                  }, childCount: visibleProjects.length),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<ProjectModel> _filterAndSortProjects(List<ProjectModel> projects) {
    final query = _projectQuery.trim().toLowerCase();
    final visible = query.isEmpty
        ? [...projects]
        : projects.where((p) => p.title.toLowerCase().contains(query)).toList();

    switch (_projectSortMode) {
      case _ProjectSortMode.updatedDesc:
        visible.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _ProjectSortMode.nameAsc:
        visible.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case _ProjectSortMode.status:
        visible.sort((a, b) {
          final status = a.status.compareTo(b.status);
          if (status != 0) return status;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    }
    return visible;
  }

  String get _projectSortLabel {
    switch (_projectSortMode) {
      case _ProjectSortMode.updatedDesc:
        return 'NEWEST';
      case _ProjectSortMode.nameAsc:
        return 'NAME';
      case _ProjectSortMode.status:
        return 'STATUS';
    }
  }

  void _showProjectSearch() {
    final ctrl = TextEditingController(text: _projectQuery);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('搜索项目'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入项目名称',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (value) {
            setState(() => _projectQuery = value.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _projectQuery = '');
              Navigator.pop(ctx);
            },
            child: Text('清除'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          ElevatedButton(
            onPressed: () {
              setState(() => _projectQuery = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showProjectsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('项目操作'),
        message: Text(
          _projectQuery.isEmpty ? '管理当前项目列表' : '当前搜索：$_projectQuery',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showNewProjectDialog();
            },
            child: Text('新建项目'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(homeProvider.notifier).loadProjects();
            },
            child: Text('刷新列表'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _projectSortMode = _ProjectSortMode.updatedDesc);
              Navigator.pop(ctx);
            },
            child: Text('按更新时间排序'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _projectSortMode = _ProjectSortMode.nameAsc);
              Navigator.pop(ctx);
            },
            child: Text('按名称排序'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _projectSortMode = _ProjectSortMode.status);
              Navigator.pop(ctx);
            },
            child: Text('按状态排序'),
          ),
          if (_projectQuery.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _projectQuery = '');
                Navigator.pop(ctx);
              },
              child: Text('清除搜索'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text('取消'),
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

    return Column(
      children: [
        Container(
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
          child: Row(
            children: [
              Expanded(
                child: _HeroStat(value: '$total', label: 'TOTAL'),
              ),
              const _MetricDivider(),
              Expanded(
                child: _HeroStat(
                  value: '$generated',
                  label: 'PLAYABLE',
                  accent: true,
                  inset: 16,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _HeroStat(value: '$drafts', label: 'DRAFT', inset: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
    );
  }

  void _confirmDelete(String id, String title) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('删除项目'),
        content: Text('确定要删除「$title」吗？\n此操作不可撤销。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(homeProvider.notifier).deleteProject(id);
              Navigator.pop(ctx);
            },
            child: Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _ProjectsNav extends StatelessWidget {
  final String query;
  final VoidCallback onSearch;
  final VoidCallback onMore;

  const _ProjectsNav({
    required this.query,
    required this.onSearch,
    required this.onMore,
  });

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
              icon: query.isEmpty
                  ? Icons.search_rounded
                  : Icons.search_off_rounded,
              onTap: onSearch,
              tooltip: query.isEmpty ? '搜索' : '修改搜索',
              size: 36,
              iconSize: 16,
            ),
            const SizedBox(width: 8),
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
          'WORKSHOP // PROJECTS',
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text('Projects.', style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }
}

enum _ProjectSortMode { updatedDesc, nameAsc, status }

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.6,
      height: 70,
      color: AppTheme.textPrimary.withValues(alpha: 0.16),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  final double inset;

  const _HeroStat({
    required this.value,
    required this.label,
    this.accent = false,
    this.inset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 14, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.padLeft(2, '0'),
            style: TextStyle(
              color: accent ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: -1,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
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
          Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(onPressed: onRetry, child: Text('重试')),
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
            child: Icon(
              Icons.gamepad_outlined,
              size: 38,
              color: AppTheme.tabProject,
            ),
          ),
          const SizedBox(height: 20),
          Text('还没有项目', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '创建第一个游戏项目，AI 会从玩法、世界观和素材方向逐步补齐。',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: onCreate,
            child: Row(
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

class _ProjectSearchEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _ProjectSearchEmptyState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 14),
          Text('没有找到项目', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '没有名称包含「$query」的项目。',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          CupertinoButton.filled(onPressed: onClear, child: Text('清除搜索')),
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
    return Dismissible(
      key: ValueKey(project.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: AppTheme.error.withValues(alpha: 0.18),
        child: Text(
          'DELETE',
          style: TextStyle(
            color: AppTheme.error,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      child: _ProjectTile(project: project, onTap: onTap, onRename: onRename),
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
    final indexText = ((widget.project.title.hashCode.abs() % 89) + 1)
        .toString()
        .padLeft(2, '0');

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () => _showRenameSheet(context),
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.72 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppTheme.textPrimary.withValues(alpha: 0.12),
                width: 0.6,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  indexText,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.project.status == 'draft'
                              ? 'DRAFT'
                              : 'PLAYABLE',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.centerRight,
                child: widget.project.status == 'draft'
                    ? ForgeChip(label: 'DRAFT', tone: ForgeChipTone.draft)
                    : ForgeChip(label: 'PLAYABLE', tone: ForgeChipTone.online),
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
        title: Text('重命名项目'),
        message: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: CupertinoTextField(
            controller: nameCtrl,
            autofocus: true,
            placeholder: '项目名称',
            clearButtonMode: OverlayVisibilityMode.editing,
            style: TextStyle(color: AppTheme.textPrimary),
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
            child: Text('确定'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text('取消'),
        ),
      ),
    );
  }
}
