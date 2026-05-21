import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/wellness_check_models.dart';
import '../chat/femai_chat_screen.dart';
import '../doctor_consultation/doctor_consultation_home_screen.dart';
import '../doctor_consultation/data/doctor_consultation_service.dart';
import '../doctor_consultation/doctor_list_screen.dart';

class WellnessCheckResultScreen extends StatelessWidget {
  final WellnessCheckResult result;
  const WellnessCheckResultScreen({super.key, required this.result});

  // Map wellness templates to doctor category slugs
  String? _getDoctorCategorySlug() {
    final title = result.templateTitle.toLowerCase();
    if (title.contains('anxiety') || title.contains('mood') || title.contains('wellbeing') || title.contains('phq') || title.contains('gad')) {
      return 'mental-wellness';
    }
    if (title.contains('pms') || title.contains('period') || title.contains('cycle')) {
      return 'gynecologist';
    }
    if (title.contains('skin') || title.contains('acne') || title.contains('hair')) {
      return 'dermatologist';
    }
    if (title.contains('nutrition') || title.contains('diet') || title.contains('weight')) {
      return 'nutritionist';
    }
    return null; // Default to general physician or home
  }

  Future<void> _navigateToDoctor(BuildContext context) async {
    final slug = _getDoctorCategorySlug();
    if (slug == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorConsultationHomeScreen()));
      return;
    }

    // Try to find the actual category object
    try {
      final service = DoctorConsultationService();
      final categories = await service.getCategories();
      final target = categories.firstWhere((c) => c.slug == slug, orElse: () => categories.first);
      
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorListScreen(category: target)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorConsultationHomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDoctorButton = result.normalizedScore < 50;
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Check Result', style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _buildScoreCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('What this means'),
            _buildExplanationCard(),
            const SizedBox(height: 32),
            if (result.contributingFactors.isNotEmpty) ...[
              _buildSectionHeader('Key Factors'),
              _buildFactorsGrid(),
              const SizedBox(height: 32),
            ],
            _buildSectionHeader('Gentle next steps'),
            _buildRecommendationsCard(),
            const SizedBox(height: 40),
            _buildDisclaimer(),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
            if (showDoctorButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToDoctor(context),
                  icon: const Icon(Icons.medical_services_outlined, size: 20),
                  label: const Text('Talk to a Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FemFlowColors.primary,
                    side: const BorderSide(color: FemFlowColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                final message = "I just completed the '${result.templateTitle}' check and scored ${result.normalizedScore}. The result label is '${result.resultLabel}'. Recommendation: ${result.recommendation}. Can you help me understand this and suggest next steps?";
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FemAIChatScreen(initialMessage: message),
                  ),
                );
              },
              child: const Text('Ask FemAI about this result', style: TextStyle(color: FemFlowColors.aiWellness, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return AppCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Text(result.templateTitle, style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: result.normalizedScore / 100,
                  strokeWidth: 14,
                  backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(FemFlowColors.primary),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${result.normalizedScore}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
                  ),
                  const Text('SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textMuted, letterSpacing: 2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: FemFlowColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.resultLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return AppCard(
      color: Colors.white,
      child: Text(
        result.recommendation ?? 'Your answers suggest a stable wellness pattern recently. Continue regular logging to improve cycle-linked insights.',
        style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary, height: 1.6),
      ),
    );
  }

  Widget _buildFactorsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: result.contributingFactors.map((f) => _buildFactorChip(f)).toList(),
    );
  }

  Widget _buildFactorChip(String factor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: FemFlowColors.aiWellness.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FemFlowColors.aiWellness.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_outlined, size: 16, color: FemFlowColors.aiWellness),
          const SizedBox(width: 8),
          Text(factor, style: const TextStyle(color: FemFlowColors.aiWellness, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final steps = [
      'Try a consistent sleep timing tonight.',
      'Stay hydrated and drink plenty of water.',
      'Log your mood for the next 3 days.',
      'Review these results with your FemAI assistant.'
    ];

    return AppCard(
      color: FemFlowColors.fertileWindow.withValues(alpha: 0.05),
      border: const BorderSide(color: FemFlowColors.fertileWindow, width: 0.5),
      child: Column(
        children: steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 20, color: FemFlowColors.fertileWindow),
              const SizedBox(width: 12),
              Expanded(child: Text(s, style: const TextStyle(fontSize: 15, color: FemFlowColors.textPrimary))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FemFlowColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: const [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: FemFlowColors.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This is an educational wellness indicator, not a medical diagnosis.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FemFlowColors.textMuted),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your answers suggest this may need extra support. If this feels severe, urgent, or affects daily life, please consider contacting a qualified doctor.',
            style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
