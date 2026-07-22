import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/exercise_models.dart';
import '../screens/exercise_detail_screen.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final String? recommendationReason;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.recommendationReason,
  });

  @override
  Widget build(BuildContext context) {
    // Determine a primary phase color for display
    final primaryPhase = exercise.cyclePhases.isNotEmpty ? exercise.cyclePhases.first : 'any_day';
    final phaseColor = _getPhaseColor(primaryPhase);

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(exercise.category),
                  color: phaseColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: FemLyraColors.textPrimary,
                            ),
                          ),
                        ),
                        if (exercise.isCustom)
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                             decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                             child: const Text('MY EXERCISE', style: TextStyle(color: FemLyraColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                           ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.durationMinutes} min • ${exercise.intensity.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: FemLyraColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recommendationReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FemLyraColors.aiWellness.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FemLyraColors.aiWellness.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recommendationReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: FemLyraColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (exercise.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              exercise.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: FemLyraColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
          if (exercise.benefits.isNotEmpty) ...[
             const SizedBox(height: 8),
             Wrap(
               spacing: 6,
               children: exercise.benefits.take(3).map((b) => Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                 child: Text(b, style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.w500)),
               )).toList(),
             ),
          ],
        ],
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
      case 'period': return FemLyraColors.period;
      case 'follicular': return FemLyraColors.primary;
      case 'ovulatory':
      case 'ovulation': return FemLyraColors.ovulation;
      case 'luteal': return Colors.orange;
      default: return FemLyraColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'gentle_yoga':
      case 'gentle yoga': return Icons.self_improvement;
      case 'stretching': return Icons.accessibility;
      case 'walking': return Icons.directions_walk;
      case 'strength':
      case 'strength training': return Icons.fitness_center;
      case 'pilates': return Icons.grid_view;
      case 'meditation': return Icons.spa;
      case 'breathing': return Icons.air;
      case 'cardio': return Icons.speed;
      default: return Icons.play_circle_outline;
    }
  }
}
