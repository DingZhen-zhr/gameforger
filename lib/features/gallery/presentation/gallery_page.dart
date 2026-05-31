import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/liquid_glass.dart';
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
        if (projects.isEmpty) {
          return _buildGalleryScroll(
            slivers: const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _GalleryMessageState(
                  icon: Icons.auto_awesome_motion_outlined,
                  title: '作品库等待生成',
                  message: '项目完成游戏生成后，会以可展开预览的形式出现在这里。',
                  accent: AppTheme.tabGallery,
                ),
              ),
            ],
          );
        }

        return _buildGalleryScroll(
          projects: projects,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              sliver: const SliverToBoxAdapter(
                child: GlassSectionHeader(
                  title: '全部作品',
                  subtitle: '轻触条目展开，直接进入可玩预览。',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final project = projects[i];
                  return ExpandableGalleryTile(
                    project: project,
                    isExpanded: _expandedProjectId == project.id,
                    onTap: () => _handleTileTap(project.id),
                    onDelete: () => _confirmDelete(project),
                  );
                }, childCount: projects.length),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGalleryScroll({
    List<ProjectModel> projects = const [],
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
}

class _GalleryHero extends StatelessWidget {
  final List<ProjectModel> projects;
  final VoidCallback? onOpenLatest;

  const _GalleryHero({required this.projects, required this.onOpenLatest});

  @override
  Widget build(BuildContext context) {
    final latest = projects.isEmpty ? null : projects.first;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(32),
      blurSigma: 28,
      tintColor: AppTheme.tabGallery,
      tintOpacity: 0.11,
      borderOpacity: 0.2,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '作品库',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '用更像 App Store 的方式展示可玩的生成结果。',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _GalleryCountBadge(count: projects.length),
            ],
          ),
          if (latest != null) ...[
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.tabGallery.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.tabGallery,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '最新生成',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  color: AppTheme.tabGallery.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onOpenLatest,
                  child: const Text(
                    '预览',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryCountBadge extends StatelessWidget {
  final int count;

  const _GalleryCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.tabGallery.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.tabGallery.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppTheme.tabGallery,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.tabGallery,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  const _GalleryMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.accent = AppTheme.textTertiary,
  });

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
            tintColor: accent,
            tintOpacity: 0.12,
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
        ],
      ),
    );
  }
}
