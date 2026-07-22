import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';

class HormonalHealthSection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const HormonalHealthSection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<HormonalHealthSection> createState() => _HormonalHealthSectionState();
}

class _HormonalHealthSectionState extends State<HormonalHealthSection> {
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
        Row(
          children: [
            Expanded(child: _buildNumberField('Avg Cycle Length', 'usual_cycle_length', suffix: 'days')),
            const SizedBox(width: 16),
            Expanded(child: _buildNumberField('Avg Period Length', 'avg_period_length', suffix: 'days')),
          ],
        ),
        const SizedBox(height: 24),
        _buildToggleField('Do you have irregular cycles?', 'irregular_cycles'),
        const SizedBox(height: 24),
        _buildLevelSelector('Typical PMS Severity', 'pms_severity'),
        const SizedBox(height: 24),
        _buildLevelSelector('Typical Period Pain', 'pain_severity'),
        const SizedBox(height: 32),
        _buildChipSelector('Medical History (Optional)', '', ['PCOS Diagnosis', 'Thyroid Issues'], isMulti: true, customMapping: {
          'PCOS Diagnosis': 'pcos_diagnosis',
          'Thyroid Issues': 'thyroid_issues'
        }),
      ],
    );
  }

  Widget _buildNumberField(String label, String key, {required String suffix}) {
    return TextField(
      keyboardType: TextInputType.number,
      onChanged: (val) => _updateField(key, int.tryParse(val) ?? 0),
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: _data[key]?.toString() ?? '',
          selection: TextSelection.collapsed(offset: (_data[key]?.toString() ?? '').length),
        ),
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
      ),
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

  Widget _buildLevelSelector(String label, String key) {
    final levels = ['Low', 'Moderate', 'High', 'Severe'];
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

  Widget _buildChipSelector(String label, String key, List<String> options, {bool isMulti = false, Map<String, String>? customMapping}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final effectiveKey = customMapping?[o] ?? key;
            final isSelected = isMulti ? (_data[effectiveKey] == true) : (_data[key] == o);
            return FilterChip(
              label: Text(o),
              selected: isSelected,
              selectedColor: FemFlowColors.primary.withValues(alpha: 0.2),
              checkmarkColor: FemFlowColors.primary,
              onSelected: (val) => _updateField(effectiveKey, val),
            );
          }).toList(),
        ),
      ],
    );
  }
}
