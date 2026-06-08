import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';
import '../../home/providers/home_provider.dart';
import '../providers/gallery_provider.dart';
import 'widgets/expandable_gallery_tile.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  String? _expandedProjectId;
  String _galleryQuery = '';
  _GallerySortMode _gallerySortMode = _GallerySortMode.updatedDesc;

  void _handleTileTap(String projectId) {
    setState(() {
      if (_expandedProjectId == projectId) {
        _expandedProjectId = null; // collapse
      } else {
        _expandedProjectId =
            projectId; // expand (collapses previous via setState)
      }
    });
  }

  void _confirmDelete(ProjectModel project) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除作品'),
        content: Text('确定要删除「${project.title}」吗？\n此操作不可撤销，项目也会同步删除。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(homeProvider.notifier).deleteProject(project.id);
              ref.invalidate(galleryProvider);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryAsync = ref.watch(galleryProvider);

    return galleryAsync.when(
      loading: () => _buildGalleryScroll(
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator(radius: 12)),
          ),
        ],
      ),
      error: (err, _) => _buildGalleryScroll(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _GalleryMessageState(
              icon: Icons.wifi_off_rounded,
              title: '加载失败',
              message: '$err',
            ),
          ),
        ],
      ),
      data: (projects) {
        final visibleProjects = _filterAndSortProjects(projects);

        if (projects.isEmpty) {
          return _buildGalleryScroll(
            slivers: const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _GalleryMessageState(
                  icon: Icons.auto_awesome_motion_outlined,
                  title: '还没有作品',
                  message: '项目完成游戏生成后，会以可展开预览的形式出现在这里。',
                  accent: AppTheme.tabGallery,
                ),
              ),
            ],
          );
        }

        return _buildGalleryScroll(
          projects: visibleProjects,
          totalCount: projects.length,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              sliver: SliverToBoxAdapter(
                child: ForgeSectionLabel(
                  title: _galleryQuery.isEmpty ? '全部作品' : '搜索结果',
                  trailing: _galleryQuery.isEmpty
                      ? _gallerySortLabel
                      : '${visibleProjects.length} 件匹配',
                ),
              ),
            ),
            if (visibleProjects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _GalleryMessageState(
                  icon: Icons.search_off_rounded,
                  title: '没有找到作品',
                  message: '没有名称包含「$_galleryQuery」的作品。',
                  accent: AppTheme.tabGallery,
                  actionLabel: '清除搜索',
                  onAction: () => setState(() => _galleryQuery = ''),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final project = visibleProjects[i];
                    return ExpandableGalleryTile(
                      project: project,
                      isExpanded: _expandedProjectId == project.id,
                      onTap: () => _handleTileTap(project.id),
                      onDelete: () => _confirmDelete(project),
                    );
                  }, childCount: visibleProjects.length),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGalleryScroll({
    List<ProjectModel> projects = const [],
    int? totalCount,
    required List<Widget> slivers,
  }) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(galleryProvider);
          return Future.value();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _GalleryNav(
                  count: totalCount ?? projects.length,
                  query: _galleryQuery,
                  onSearch: _showGallerySearch,
                  onMore: () => _showGalleryMenu(projects),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _GalleryHero(
                  projects: projects,
                  onOpenLatest: projects.isEmpty
                      ? null
                      : () => context.push(
                          '/project/${projects.first.id}/preview',
                        ),
                ),
              ),
            ),
            ...slivers,
          ],
        ),
      ),
    );
  }

  List<ProjectModel> _filterAndSortProjects(List<ProjectModel> projects) {
    final query = _galleryQuery.trim().toLowerCase();
    final visible = query.isEmpty
        ? [...projects]
        : projects.where((p) => p.title.toLowerCase().contains(query)).toList();

    switch (_gallerySortMode) {
      case _GallerySortMode.updatedDesc:
        visible.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _GallerySortMode.nameAsc:
        visible.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return visible;
  }

  String get _gallerySortLabel {
    switch (_gallerySortMode) {
      case _GallerySortMode.updatedDesc:
        return '按更新时间';
      case _GallerySortMode.nameAsc:
        return '按名称';
    }
  }

  void _showGallerySearch() {
    final ctrl = TextEditingController(text: _galleryQuery);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜索作品'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入作品名称',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (value) {
            setState(() => _galleryQuery = value.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _galleryQuery = '');
              Navigator.pop(ctx);
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _galleryQuery = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showGalleryMenu(List<ProjectModel> visibleProjects) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('作品操作'),
        message: Text(_galleryQuery.isEmpty ? '管理作品列表' : '当前搜索：$_galleryQuery'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ref.invalidate(galleryProvider);
            },
            child: const Text('刷新作品'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _expandedProjectId = null);
              Navigator.pop(ctx);
            },
            child: const Text('折叠全部预览'),
          ),
          if (visibleProjects.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/project/${visibleProjects.first.id}/preview');
              },
              child: const Text('打开第一个可见作品'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _gallerySortMode = _GallerySortMode.updatedDesc);
              Navigator.pop(ctx);
            },
            child: const Text('按更新时间排序'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _gallerySortMode = _GallerySortMode.nameAsc);
              Navigator.pop(ctx);
            },
            child: const Text('按名称排序'),
          ),
          if (_galleryQuery.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _galleryQuery = '');
                Navigator.pop(ctx);
              },
              child: const Text('清除搜索'),
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

class _GalleryNav extends StatelessWidget {
  final int count;
  final String query;
  final VoidCallback onSearch;
  final VoidCallback onMore;

  const _GalleryNav({
    required this.count,
    required this.query,
    required this.onSearch,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '作品',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '已生成作品 · $count 个',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ForgeIconButton(
          icon: query.isEmpty ? Icons.search_rounded : Icons.search_off_rounded,
          onTap: onSearch,
          tooltip: query.isEmpty ? '搜索' : '修改搜索',
          glow: query.isNotEmpty,
          accent: AppTheme.tabGallery,
        ),
        const SizedBox(width: 8),
        ForgeIconButton(
          icon: Icons.more_horiz_rounded,
          onTap: onMore,
          tooltip: '更多',
          accent: AppTheme.tabGallery,
        ),
      ],
    );
  }
}

enum _GallerySortMode { updatedDesc, nameAsc }

class _GalleryHero extends StatelessWidget {
  final List<ProjectModel> projects;
  final VoidCallback? onOpenLatest;

  const _GalleryHero({required this.projects, required this.onOpenLatest});

  @override
  Widget build(BuildContext context) {
    final latest = projects.isEmpty ? null : projects.first;

    if (latest == null) {
      return const ForgeGlassCard(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        accent: AppTheme.secondary,
        accentOpacity: 0.06,
        borderOpacity: 0.12,
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            NebulaOrb(size: 50, spin: false),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '还没有作品',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '生成完成的游戏会出现在这里。',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onOpenLatest,
      child: SizedBox(
        height: 208,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.45, -0.68),
                      radius: 1.1,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.58),
                        AppTheme.secondary.withValues(alpha: 0.2),
                        AppTheme.bgDark,
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.32),
                      width: 0.8,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _GalleryShowcasePainter(latest.title.hashCode),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 42, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ForgeChip(
                                  label: '可玩',
                                  tone: ForgeChipTone.cyan,
                                  dot: true,
                                ),
                                ForgeChip(
                                  label: 'Canvas',
                                  tone: ForgeChipTone.violet,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              latest.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatTime(latest.updatedAt)} 生成',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ForgePrimaryButton(
                        label: '运行',
                        icon: Icons.bolt_rounded,
                        onPressed: onOpenLatest,
                        accent: AppTheme.secondary,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 12,
                child: Text(
                  '最新生成',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final daysAgo = DateTime.now().difference(dt).inDays;
    if (daysAgo == 0) return '今天';
    if (daysAgo == 1) return '昨天';
    return '$daysAgo 天前';
  }
}

class _GalleryShowcasePainter extends CustomPainter {
  final int seed;

  const _GalleryShowcasePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 22; i++) {
      final x = size.width * (0.06 + i * 0.043);
      final y = size.height * (0.48 + _wave(seed + i) * 0.18);
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.45, starPaint);
    }

    final core = Offset(size.width * 0.35, size.height * 0.5);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.cyan.withValues(alpha: 0.78),
          AppTheme.primary.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: core, radius: size.width * 0.22));
    canvas.drawCircle(core, size.width * 0.2, glow);
    canvas.drawCircle(core, 5.5, Paint()..color = Colors.white);

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.62,
        size.width * 0.92,
        size.height * 0.8,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.secondary.withValues(alpha: 0.55)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke,
    );

    final second = Path()
      ..moveTo(size.width * 0.08, size.height * 0.89)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.72,
        size.width * 0.92,
        size.height * 0.88,
      );
    canvas.drawPath(
      second,
      Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.44)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  double _wave(int value) {
    return math.sin(value * 0.71);
  }

  @override
  bool shouldRepaint(covariant _GalleryShowcasePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _GalleryMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _GalleryMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.accent = AppTheme.textTertiary,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ForgeGlassCard(
            borderRadius: BorderRadius.circular(26),
            accent: accent,
            accentOpacity: 0.1,
            padding: const EdgeInsets.all(18),
            child: Icon(icon, size: 38, color: accent),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            CupertinoButton.filled(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
