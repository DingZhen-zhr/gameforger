import 'package:flutter/material.dart';
import '../../domain/card_model.dart';
import '../../../../core/theme/app_theme.dart';

class CardViewWidget extends StatelessWidget {
  final CardModel card;

  const CardViewWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bgColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 16, color: _bgColor),
              const SizedBox(width: 8),
              Text(
                card.content['_label'] as String? ?? card.type.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _bgColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildContent(context),
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (card.type) {
      case CardType.story:
        return const Color(0xFF4FC3F7);
      case CardType.art:
        return const Color(0xFFFFB74D);
      case CardType.gameplay:
        return const Color(0xFF81C784);
      case CardType.asset:
        return const Color(0xFFE57373);
      case CardType.music:
        return const Color(0xFFBA68C8);
      case CardType.question:
        return const Color(0xFF4DD0E1);
      case CardType.userNote:
        return AppTheme.textSecondary;
    }
  }

  IconData get _icon {
    switch (card.type) {
      case CardType.story:
        return Icons.menu_book;
      case CardType.art:
        return Icons.palette;
      case CardType.gameplay:
        return Icons.sports_esports;
      case CardType.asset:
        return Icons.inventory_2;
      case CardType.music:
        return Icons.music_note;
      case CardType.question:
        return Icons.help_outline;
      case CardType.userNote:
        return Icons.edit_note;
    }
  }

  List<Widget> _buildContent(BuildContext context) {
    final c = card.content;
    final entries = <Widget>[];

    c.forEach((key, value) {
      if (key == '_label') return;
      if (key == '_type') return;
      entries.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
          ),
        ),
      );
    });

    if (entries.isEmpty) {
      entries.add(
        Text(
          '(空)',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return entries;
  }
}
