import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import 'custom_plan_models.dart';
import 'custom_plan_service.dart';
import 'custom_plan_result_screen.dart';
import 'widgets/custom_plan_summary_card.dart';

class CustomPlanReviewScreen extends StatefulWidget {
  final CustomNutritionPlan plan;

  const CustomPlanReviewScreen({super.key, required this.plan});

  @override
  State<CustomPlanReviewScreen> createState() => _CustomPlanReviewScreenState();
}

class _CustomPlanReviewScreenState extends State<CustomPlanReviewScreen> {
  final CustomPlanService _service = CustomPlanService();
  bool _isGenerating = false;

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);
    try {
      // 1. Create the plan record
      final createdPlan = await _service.createCustomPlan(widget.plan);
      
      // 2. Trigger generation on backend
      if (createdPlan.id != null) {
        final generatedPlan = await _service.generatePlan(createdPlan.id!);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CustomPlanResultScreen(plan: generatedPlan),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating plan: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Review & Generate'),
      ),
      body: _isGenerating 
        ? _buildGeneratingState()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Plan Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please confirm these details before we build your meal plan.',
                  style: TextStyle(color: FemFlowColors.textSecondary),
                ),
                _buildSafetyNote(),
                const SizedBox(height: 16),
                CustomPlanSummaryCard(plan: widget.plan),
                const SizedBox(height: 40),
                PrimaryButton(
                  label: 'Generate Custom Plan',
                  onPressed: _generatePlan,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 8),
          ),
          const SizedBox(height: 32),
          const Text(
            'Personalizing your plan...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'FemAI is matching your goals, preferences, and doctor advice with optimal nutrients.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FemFlowColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This plan is for wellness support and should not replace medical advice. Always consult your doctor for medical conditions.',
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
