import 'package:flutter/material.dart';
import '../../../../core/theme/FemLyra_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class CalorieRequirementCard extends StatelessWidget {
  final int calories;
  final String explanation;
  final bool isManual;
  final VoidCallback? onEdit;

  const CalorieRequirementCard({
    super.key,
    required this.calories,
    required this.explanation,
    this.isManual = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: FemLyraColors.primary.withValues(alpha: 0.05),
      border: BorderSide(color: FemLyraColors.primary.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Calorie Requirement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: FemLyraColors.primary),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$calories',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: FemLyraColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kcal / day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FemLyraColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 13,
              color: FemLyraColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (calories < 1200) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Very low calorie plans may be unsafe. Please follow only under medical supervision.',
                      style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
