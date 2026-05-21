import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';

class HealthWellnessSection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const HealthWellnessSection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<HealthWellnessSection> createState() => _HealthWellnessSectionState();
}

class _HealthWellnessSectionState extends State<HealthWellnessSection> {
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

  int _calculateInitialWellness() {
    int score = 65;
    if (_data['stress_level'] == 'low') score += 10;
    if (_data['energy_level'] == 'high') score += 10;
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoalSelector(),
        const SizedBox(height: 32),
        _buildLevelSelector('Current Stress Level', 'stress_level'),
        const SizedBox(height: 24),
        _buildLevelSelector('Typical Energy Level', 'energy_level'),
        const SizedBox(height: 24),
        _buildLevelSelector('Anxiety Frequency', 'anxiety_frequency', isFrequency: true),
        const SizedBox(height: 32),
        _buildInitialWellnessPreview(),
      ],
    );
  }

  Widget _buildGoalSelector() {
    final goals = [
      {'val': 'track_cycle', 'label': 'Track Cycle', 'icon': Icons.calendar_today},
      {'val': 'conceive', 'label': 'Get Pregnant', 'icon': Icons.child_care},
      {'val': 'avoid_pregnancy', 'label': 'Avoid Pregnancy', 'icon': Icons.shield},
      {'val': 'hormonal_balance', 'label': 'Hormonal Balance', 'icon': Icons.balance},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What is your primary goal?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...goals.map((g) {
          final isSelected = _data['goal'] == g['val'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => _updateField('goal', g['val']),
              color: isSelected ? FemFlowColors.blushMist : Colors.white,
              border: BorderSide(color: isSelected ? FemFlowColors.primary : FemFlowColors.border),
              child: Row(
                children: [
                  Icon(g['icon'] as IconData, color: isSelected ? FemFlowColors.primary : FemFlowColors.textSecondary),
                  const SizedBox(width: 16),
                  Text(g['label'] as String, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? FemFlowColors.primary : FemFlowColors.textPrimary)),
                  const Spacer(),
                  if (isSelected) const Icon(Icons.check_circle, color: FemFlowColors.primary, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLevelSelector(String label, String key, {bool isFrequency = false}) {
    final levels = isFrequency ? ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'] : ['Low', 'Moderate', 'High', 'Severe'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: levels.map((l) {
            final isSelected = _data[key] == l.toLowerCase();
            return Expanded(
              child: GestureDetector(
                onTap: () => _updateField(key, l.toLowerCase()),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? FemFlowColors.primary : Colors.white,
                    border: Border.all(color: isSelected ? FemFlowColors.primary : FemFlowColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : FemFlowColors.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInitialWellnessPreview() {
    final score = _calculateInitialWellness();
    return AppCard(
      color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        children: [
          const Text('Predicted Wellness Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
          const SizedBox(height: 8),
          Text('$score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
          const Text('Based on your current input', style: TextStyle(fontSize: 10, color: FemFlowColors.textSecondary)),
        ],
      ),
    );
  }
}
