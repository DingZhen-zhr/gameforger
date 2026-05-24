import 'package:flutter/material.dart';
import '../../domain/game_spec.dart';
import '../../../../core/theme/app_theme.dart';

class GameSpecProgress extends StatelessWidget {
  final GameSpec spec;
  final VoidCallback? onTap;

  const GameSpecProgress({super.key, required this.spec, this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final filled = items.where((e) => e.$2 != null).length;
    final total = items.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            bottom: BorderSide(color: AppTheme.outlineDark.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, size: 16, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '游戏创意维度',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const Spacer(),
                Text(
                  '$filled / $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: filled == total ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: items.map((e) {
                    final isFilled = e.$2 != null;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isFilled ? AppTheme.primary : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          e.$1,
                          style: TextStyle(
                            fontSize: 9,
                            color: isFilled ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on GameSpecProgress {
  List<(String, String?)> get _items {
    final s = spec;
    return [
      ('类型', s.genre),
      ('主题', s.theme),
      ('美术', s.artStyle),
      ('视角', s.cameraView),
      ('机制', s.coreMechanic),
      ('能力', s.playerAbility),
      ('目标', s.goal),
      ('音乐', s.musicVibe),
      ('难度', s.difficulty),
    ];
  }
}
