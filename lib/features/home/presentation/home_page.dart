import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_utils.dart';
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
              final project =
                  await ref.read(homeProvider.notifier).createProject(title);
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
      appBar: AppBar(
        title: const Text('GameForger'),
        backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          if (_currentTab == 0)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: _showNewProjectDialog,
              child: const Icon(Icons.add, color: AppTheme.primary, size: 26),
            ),
        ],
        bottom: homeState.isOffline
            ? const PreferredSize(
                preferredSize: Size.fromHeight(28),
                child: ColoredBox(
                  color: AppTheme.gold,
                  child: SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: Center(
                      child: Text('离线模式 — 显示本地缓存数据',
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildProjectList(homeState),
          const GalleryPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.72),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentTab,
              onTap: (i) => setState(() => _currentTab = i),
              backgroundColor: Colors.transparent,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: '项目',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.collections_bookmark_rounded),
                  label: '作品库',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: '设置',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList(HomeState homeState) {
    if (homeState.isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 12),
      );
    }

    if (homeState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text('加载失败',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(homeState.error!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: () =>
                    ref.read(homeProvider.notifier).loadProjects(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (homeState.projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.gamepad_outlined,
                    size: 36, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text('还没有项目',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                '点击右上角 + 开始你的第一个游戏',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _showNewProjectDialog,
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
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).loadProjects(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: homeState.projects.length,
          itemBuilder: (_, i) {
            final project = homeState.projects[i];
            return _SwipeableProjectTile(
              project: project,
              onTap: () => context.push('/project/${project.id}/workspace'),
              onDelete: () => _confirmDelete(project.id, project.title),
              onRename: (title) =>
                  ref.read(homeProvider.notifier).renameProject(project.id, title),
            );
          },
        ),
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
              Text('删除',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        child: _ProjectTile(
          project: project,
          onTap: onTap,
          onRename: onRename,
        ),
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
    final timeStr =
        daysAgo == 0 ? '今天' : daysAgo == 1 ? '昨天' : '$daysAgo 天前';

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.videogame_asset_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.project.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(timeStr,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textTertiary, size: 20),
                  ],
                ),
              ),
            ),
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
