import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../models/tips_models.dart';
import '../tips_detail_screen.dart';

class DailyTipCard extends StatelessWidget {
  final DailyTipCardModel tip;

  const DailyTipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TipsDetailScreen(
              tipKey: tip.categoryKey,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tip.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tip.color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tip.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconData(tip.icon), color: tip.color, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              tip.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18, 
                color: FemFlowColors.textPrimary,
                letterSpacing: -0.5
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tip.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: tip.color.withValues(alpha: 0.8), 
                fontWeight: FontWeight.w600,
                height: 1.1
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'cycle_day': return Icons.calendar_today;
      case 'phase': return Icons.waves;
      case 'fertility': return Icons.favorite;
      case 'symptoms': return Icons.healing;
      case 'hormones': return Icons.science;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      case 'fitness_center': return Icons.fitness_center;
      case 'restaurant': return Icons.restaurant;
      case 'spa': return Icons.spa;
      case 'favorite': return Icons.favorite;
      default: return Icons.tips_and_updates;
    }
  }
}
