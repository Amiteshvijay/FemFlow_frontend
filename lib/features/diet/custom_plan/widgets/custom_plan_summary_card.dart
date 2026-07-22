import 'package:flutter/material.dart';
import '../../../../core/theme/FemLyra_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../custom_plan_models.dart';

class CustomPlanSummaryCard extends StatelessWidget {
  final CustomNutritionPlan plan;

  const CustomPlanSummaryCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _summaryRow(Icons.track_changes, 'Goal', plan.goal.replaceAll('_', ' ').toUpperCase()),
          const Divider(height: 24),
          _summaryRow(Icons.bolt, 'Calories', '${plan.targetCalories} kcal/day'),
          const Divider(height: 24),
          _summaryRow(Icons.restaurant_menu, 'Meal Pattern', plan.mealFrequency.replaceAll('_', ' ')),
          const Divider(height: 24),
          _summaryRow(Icons.eco, 'Diet Type', plan.dietType),
          const Divider(height: 24),
          _summaryRow(Icons.warning_amber_rounded, 'Allergies', plan.allergies.isEmpty ? 'None' : plan.allergies.join(', ')),
          const Divider(height: 24),
          _summaryRow(Icons.medical_services_outlined, 'Doctor Advice', plan.doctorAdviceEnabled ? 'Included' : 'None'),
          const Divider(height: 24),
          _summaryRow(Icons.fitness_center, 'Exercise Link', plan.exerciseLinkEnabled ? 'Enabled' : 'Disabled'),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FemFlowColors.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: FemFlowColors.primary),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
