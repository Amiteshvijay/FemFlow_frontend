import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_check_models.dart';
import 'wellness_check_question_screen.dart';

class WellnessCheckIntroScreen extends StatefulWidget {
  final String templateCode;
  const WellnessCheckIntroScreen({super.key, required this.templateCode});

  @override
  State<WellnessCheckIntroScreen> createState() => _WellnessCheckIntroScreenState();
}

class _WellnessCheckIntroScreenState extends State<WellnessCheckIntroScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  WellnessCheckTemplate? _template;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final template = await _service.getWellnessCheckDetail(widget.templateCode);
      setState(() {
        _template = template;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading check: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: FemFlowColors.primary)));
    }

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _template!.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              _template!.description,
              style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildInfoRow(Icons.help_outline, '${_template!.questionCount} questions'),
            _buildInfoRow(Icons.timer_outlined, 'Around ${_template!.estimatedMinutes} minute'),
            _buildInfoRow(Icons.lock_outline, 'Private and secure'),
            _buildInfoRow(Icons.info_outline, 'Not a medical diagnosis'),
            const SizedBox(height: 32),
            AppCard(
              color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How this helps:', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
                  const SizedBox(height: 12),
                  const Text('• Understand recent patterns', style: TextStyle(fontSize: 14, height: 1.6)),
                  const Text('• Improve Accuracy Level', style: TextStyle(fontSize: 14, height: 1.6)),
                  Text('• Personalize your ${(_template!.inspiredBy != null ? _template!.inspiredBy!.split(' ').first : "Wellness")} insights', style: const TextStyle(fontSize: 14, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Start Check',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => WellnessCheckQuestionScreen(template: _template!)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later', style: TextStyle(color: FemFlowColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: FemFlowColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
