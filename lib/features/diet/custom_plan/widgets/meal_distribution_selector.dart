import 'package:flutter/material.dart';
import '../../../../core/theme/femflow_colors.dart';

class MealDistributionSelector extends StatelessWidget {
  final Map<String, int> distribution;
  final ValueChanged<Map<String, int>> onChanged;

  const MealDistributionSelector({
    super.key,
    required this.distribution,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Calorie Distribution (%)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...distribution.keys.map((meal) => _buildSlider(meal)),
        const SizedBox(height: 12),
        _buildTotalCheck(),
      ],
    );
  }

  Widget _buildSlider(String meal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(meal.substring(0, 1).toUpperCase() + meal.substring(1), style: const TextStyle(fontSize: 14)),
            Text('${distribution[meal]}%', style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
          ],
        ),
        Slider(
          value: distribution[meal]!.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: FemFlowColors.primary,
          inactiveColor: FemFlowColors.primary.withValues(alpha: 0.1),
          onChanged: (val) {
            final newDist = Map<String, int>.from(distribution);
            newDist[meal] = val.round();
            onChanged(newDist);
          },
        ),
      ],
    );
  }

  Widget _buildTotalCheck() {
    final total = distribution.values.reduce((a, b) => a + b);
    final isValid = total == 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.error, color: isValid ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 12),
          Text(
            'Total: $total% (Target 100%)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
