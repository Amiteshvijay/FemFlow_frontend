import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';

class BodyFitnessSection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const BodyFitnessSection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<BodyFitnessSection> createState() => _BodyFitnessSectionState();
}

class _BodyFitnessSectionState extends State<BodyFitnessSection> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initialData);
  }

  void _updateField(String key, dynamic value) {
    setState(() => _data[key] = value);
    widget.onChanged(_data);
  }

  double _calculateBMI() {
    final height = _data['height_cm'] as num?;
    final weight = _data['weight_kg'] as num?;
    if (height != null && weight != null && height > 0) {
      final hm = height / 100;
      return double.parse((weight / (hm * hm)).toStringAsFixed(1));
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBMI();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBMICard(bmi),
        const SizedBox(height: 32),
        _buildSliderField('Height (cm)', 'height_cm', min: 100, max: 250, divisions: 150),
        const SizedBox(height: 20),
        _buildSliderField('Weight (kg)', 'weight_kg', min: 30, max: 200, divisions: 170),
        const SizedBox(height: 32),
        _buildChipSelector('Body Type', 'body_type', ['Slim', 'Athletic', 'Average', 'Curvy', 'Plus Size']),
        const SizedBox(height: 24),
        _buildChipSelector('Fitness Level', 'fitness_level', ['Beginner', 'Moderate', 'Active', 'Athlete']),
        const SizedBox(height: 24),
        _buildChipSelector('Daily Activity', 'activity_level', ['Mostly Sitting', 'Light Walking', 'Active Lifestyle', 'Heavy Workout']),
      ],
    );
  }

  Widget _buildBMICard(double bmi) {
    String category = 'Normal';
    Color color = Colors.green;
    if (bmi > 0) {
      if (bmi < 18.5) { category = 'Underweight'; color = Colors.orange; }
      else if (bmi > 25 && bmi < 30) { category = 'Overweight'; color = Colors.orange; }
      else if (bmi >= 30) { category = 'Obese'; color = Colors.red; }
    }

    return AppCard(
      color: FemFlowColors.blushMist,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('Calculated BMI', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
              Text(bmi > 0 ? bmi.toString() : '--', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
            ],
          ),
          Container(height: 40, width: 1, color: FemFlowColors.border),
          Column(
            children: [
              const Text('Category', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
              Text(bmi > 0 ? category : 'Enter Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderField(String label, String key, {required double min, required double max, int? divisions}) {
    double currentVal = (_data[key] as num?)?.toDouble() ?? min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(currentVal.toStringAsFixed(0), style: const TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Slider(
          value: currentVal,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: FemFlowColors.primary,
          onChanged: (val) => _updateField(key, val),
        ),
      ],
    );
  }

  Widget _buildChipSelector(String label, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final isSelected = _data[key] == o;
            return FilterChip(
              label: Text(o),
              selected: isSelected,
              selectedColor: FemFlowColors.primary.withValues(alpha: 0.2),
              checkmarkColor: FemFlowColors.primary,
              onSelected: (val) => _updateField(key, val ? o : null),
            );
          }).toList(),
        ),
      ],
    );
  }
}
