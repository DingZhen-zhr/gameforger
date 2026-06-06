import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_forge.dart';
import '../../domain/game_spec.dart';

/// Interactive stacked cards showing all filled specification dimensions.
/// Swipe the top card left or right to cycle through the deck with animation.
class SpecCardsPanel extends StatefulWidget {
  final GameSpec spec;
  final Set<String> filledDimKeys;
  final void Function(String dimKey, String label, String currentValue) onEdit;
  final void Function(String dimKey, String label) onRediscuss;

  const SpecCardsPanel({
    super.key,
    required this.spec,
    required this.filledDimKeys,
    required this.onEdit,
    required this.onRediscuss,
  });

  @override
  State<SpecCardsPanel> createState() => _SpecCardsPanelState();
}

class _CardData {
  final String dimKey;
  final IconData icon;
  final String label;
  final String value;
  const _CardData(this.dimKey, this.icon, this.label, this.value);
}

class _CardPosition {
  final double scale;
  final double translateY;
  final double opacity;
  const _CardPosition({
    required this.scale,
    required this.translateY,
    required this.opacity,
  });
}

class _SpecCardsPanelState extends State<SpecCardsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late List<_CardData> _cards;
  int _topIndex = 0;
  double _dragDx = 0;
  bool _isFlyingOut = false;
  double _flyStartDx = 0;
  double _snapStartDx = 0;

  static const _dimIcons = <String, IconData>{
    'genre': Icons.sports_esports,
    'theme': Icons.menu_book,
    'art_style': Icons.palette,
    'camera_view': Icons.visibility,
    'core_mechanic': Icons.precision_manufacturing,
    'player_ability': Icons.fitness_center,
    'goal': Icons.flag,
    'music_vibe': Icons.music_note,
    'difficulty': Icons.bar_chart,
  };

  static const _dimLabels = <String, String>{
    'genre': '玩法类型',
    'theme': '主题/故事',
    'art_style': '美术风格',
    'camera_view': '视角',
    'core_mechanic': '核心机制',
    'player_ability': '玩家能力',
    'goal': '目标',
    'music_vibe': '音乐氛围',
    'difficulty': '难度',
  };

  static const _dimOrder = [
    'genre',
    'theme',
    'art_style',
    'camera_view',
    'core_mechanic',
    'player_ability',
    'goal',
    'music_vibe',
    'difficulty',
  ];

  static const _positions = [
    _CardPosition(scale: 1.0, translateY: 0, opacity: 1.0),
    _CardPosition(scale: 0.94, translateY: 10, opacity: 0.85),
    _CardPosition(scale: 0.89, translateY: 18, opacity: 0.6),
    _CardPosition(scale: 0.84, translateY: 24, opacity: 0.35),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _ctrl.addListener(_onAnimUpdate);
    _ctrl.addStatusListener(_onAnimStatus);
    _buildCards();
  }

  void _buildCards() {
    _cards = [];
    for (final key in _dimOrder) {
      final value = widget.spec.getValue(key);
      if (value == null || !widget.filledDimKeys.contains(key)) continue;
      _cards.add(_CardData(key, _dimIcons[key]!, _dimLabels[key]!, value));
    }
  }

  @override
  void didUpdateWidget(covariant SpecCardsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildCards();
    if (_topIndex >= _cards.length) _topIndex = 0;
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onAnimUpdate);
    _ctrl.removeStatusListener(_onAnimStatus);
    _ctrl.dispose();
    super.dispose();
  }

  void _onAnimUpdate() {
    setState(() {
      final t = _ctrl.value;
      if (_isFlyingOut) {
        final dir = _flyStartDx.sign;
        _dragDx = _flyStartDx + dir * 450 * Curves.easeOut.transform(t);
      } else {
        _dragDx = _snapStartDx * (1 - Curves.elasticOut.transform(t));
      }
    });
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        if (_isFlyingOut) {
          _topIndex = (_topIndex + 1) % _cards.length;
          _isFlyingOut = false;
        }
        _dragDx = 0;
        _snapStartDx = 0;
      });
      _ctrl.reset();
    }
  }

  void _onPanStart(DragStartDetails d) {
    if (_ctrl.isAnimating) return;
    setState(() => _dragDx = 0);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_ctrl.isAnimating) return;
    setState(() => _dragDx += d.delta.dx);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_ctrl.isAnimating) return;
    if (_dragDx.abs() > 80) {
      setState(() {
        _isFlyingOut = true;
        _flyStartDx = _dragDx;
      });
    } else {
      _snapStartDx = _dragDx;
    }
    _ctrl.forward(from: 0);
  }

  _CardPosition _interpolatedPosition(int offsetFromTop, double animT) {
    if (_isFlyingOut && offsetFromTop == 0) {
      return _positions[0];
    }
    final int idx = offsetFromTop.clamp(0, _positions.length - 1);
    final int nextIdx = (offsetFromTop - 1).clamp(0, _positions.length - 1);
    final from = _positions[idx];
    final to = _positions[nextIdx];
    final effectiveT = _isFlyingOut ? animT : 0;
    return _CardPosition(
      scale: from.scale + (to.scale - from.scale) * effectiveT,
      translateY:
          from.translateY + (to.translateY - from.translateY) * effectiveT,
      opacity: from.opacity + (to.opacity - from.opacity) * effectiveT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '设定卡片',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_cards.length} 项 · 左右滑动切换',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 136, child: _buildCardStack()),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    final visibleCount = (_cards.length < 4) ? _cards.length : 4;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(visibleCount, (i) {
        final cardIdx = (_topIndex + i) % _cards.length;
        final card = _cards[cardIdx];
        final isTop = i == 0;
        final pos = _interpolatedPosition(i, _ctrl.value);

        Widget cardWidget = Opacity(
          opacity: pos.opacity,
          child: Transform.scale(
            scale: pos.scale,
            child: _SpecCard(
              icon: card.icon,
              label: card.label,
              value: card.value,
              dimKey: card.dimKey,
              onTapEdit: () =>
                  widget.onEdit(card.dimKey, card.label, card.value),
              onTapDiscuss: () => widget.onRediscuss(card.dimKey, card.label),
            ),
          ),
        );

        // Apply vertical position offset (cards behind shift down)
        cardWidget = Transform.translate(
          offset: Offset(0, pos.translateY),
          child: cardWidget,
        );

        // Apply horizontal drag/fall-off to top card only
        if (isTop) {
          cardWidget = Transform.translate(
            offset: Offset(_dragDx, 0),
            child: cardWidget,
          );

          // Rotation during drag for physical feel
          final rotation = (_dragDx / 800).clamp(-0.15, 0.15);
          cardWidget = Transform.rotate(angle: rotation, child: cardWidget);

          cardWidget = GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: cardWidget,
          );
        } else {
          cardWidget = IgnorePointer(child: cardWidget);
        }

        return Positioned(left: 0, right: 0, top: 4, child: cardWidget);
      }).reversed.toList(), // reverse so top card (i=0) renders on top
    );
  }
}

class _SpecCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String dimKey;
  final VoidCallback onTapEdit;
  final VoidCallback onTapDiscuss;

  const _SpecCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.dimKey,
    required this.onTapEdit,
    required this.onTapDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    return ForgeGlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      accent: AppTheme.primary,
      accentOpacity: 0.07,
      borderOpacity: 0.16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, size: 15, color: AppTheme.cyan),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const ForgeChip(label: '已锁', tone: ForgeChipTone.violet),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MiniButton(
                icon: Icons.edit_outlined,
                tooltip: '编辑',
                onTap: onTapEdit,
              ),
              const SizedBox(width: 4),
              _MiniButton(
                icon: Icons.chat_bubble_outline,
                tooltip: '重新讨论',
                onTap: onTapDiscuss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Icon(icon, size: 14, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
