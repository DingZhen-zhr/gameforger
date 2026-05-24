import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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
        _expandedProjectId = projectId; // expand (collapses previous via setState)
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
      loading: () => const Center(
        child: CupertinoActivityIndicator(radius: 12),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('$err',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (projects) {
        if (projects.isEmpty) {
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
                    child: const Icon(Icons.photo_library_outlined,
                        size: 36, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('作品库',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text(
                    '完成游戏生成后，作品会出现在这里',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () {
            ref.invalidate(galleryProvider);
            return Future.value();
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: projects.length,
            itemBuilder: (_, i) {
              final project = projects[i];
              return ExpandableGalleryTile(
                project: project,
                isExpanded: _expandedProjectId == project.id,
                onTap: () => _handleTileTap(project.id),
                onDelete: () => _confirmDelete(project),
              );
            },
          ),
        );
      },
    );
  }
}
