import 'package:flutter/material.dart';
import '../../domain/game_spec.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_forge.dart';

class GameSpecProgress extends StatelessWidget {
  final GameSpec spec;
  final VoidCallback? onTap;

  const GameSpecProgress({super.key, required this.spec, this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final filled = items.where((e) => e.$2 != null).length;
    final total = items.length;
    final progress = total == 0 ? 0.0 : filled / total;

    return GestureDetector(
      onTap: onTap,
      child: ForgeGlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(20),
        accent: AppTheme.primary,
        accentOpacity: 0.06,
        borderOpacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '创意维度 · 能量校准',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ForgeChip(
                  label: '${(progress * 100).round()}%',
                  tone: progress >= 1
                      ? ForgeChipTone.online
                      : ForgeChipTone.violet,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
              childAspectRatio: 3.8,
              physics: const NeverScrollableScrollPhysics(),
              children: items.map((item) {
                final isFilled = item.$2 != null;
                return _DimensionEnergy(
                  label: item.$1,
                  value: isFilled ? 1 : 0.18,
                  color: isFilled ? AppTheme.primary : AppTheme.secondary,
                );
              }).toList(),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$filled / $total 已锁定',
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionEnergy extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _DimensionEnergy({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ForgeEnergyBar(value: value, color: color, height: 3),
      ],
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
