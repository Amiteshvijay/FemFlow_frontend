import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';

class PrivacyAISection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const PrivacyAISection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<PrivacyAISection> createState() => _PrivacyAISectionState();
}

class _PrivacyAISectionState extends State<PrivacyAISection> {
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
        _buildConsentCard(),
        const SizedBox(height: 32),
        _buildToggleField('Allow anonymous wellness insights', 'anonymous_wellness_insights'),
        const SizedBox(height: 16),
        _buildToggleField('Allow personalized AI recommendations', 'ai_recommendations_consent'),
        const SizedBox(height: 16),
        _buildToggleField('Allow symptom-based prediction', 'symptom_prediction_consent'),
        const SizedBox(height: 40),
        const AppCard(
          color: Colors.green,
          child: Row(
            children: [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Your health data is encrypted and never shared without permission.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsentCard() {
    return AppCard(
      color: FemFlowColors.blushMist,
      child: Column(
        children: [
          const Icon(Icons.security, color: FemFlowColors.primary, size: 40),
          const SizedBox(height: 16),
          const Text('Clinical-Grade Privacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'We use your health data ONLY to provide personalized insights and predictions. Your data is never sold or used for public AI training.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, height: 1.5),
          ),
        ],
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
}
