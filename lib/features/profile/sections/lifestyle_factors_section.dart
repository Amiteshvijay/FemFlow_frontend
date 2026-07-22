import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';

class LifestyleFactorsSection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const LifestyleFactorsSection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<LifestyleFactorsSection> createState() => _LifestyleFactorsSectionState();
}

class _LifestyleFactorsSectionState extends State<LifestyleFactorsSection> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleField('Do you smoke?', 'smoking'),
        const SizedBox(height: 20),
        _buildLevelSelector('Alcohol Consumption', 'alcohol_consumption', isFrequency: true),
        const SizedBox(height: 24),
        _buildLevelSelector('Caffeine Intake', 'caffeine_intake', isFrequency: true),
        const SizedBox(height: 24),
        _buildLevelSelector('Sleep Quality', 'sleep_quality'),
        const SizedBox(height: 24),
        _buildToggleField('Do you work night shifts?', 'night_shift_work'),
        const SizedBox(height: 20),
        _buildToggleField('Stressful work environment?', 'stressful_work_environment'),
        const SizedBox(height: 32),
        _buildChipSelector('Dietary Preference', 'dietary_preference', ['Balanced', 'Vegetarian', 'Vegan', 'High Protein', 'Irregular', 'Other']),
      ],
    );
  }

  Widget _buildToggleField(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      value: _data[key] == true,
      onChanged: (val) => _updateField(key, val),
      activeThumbColor: FemFlowColors.primary,
      contentPadding: EdgeInsets.zero,
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
