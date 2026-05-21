import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/wellness_score_service.dart';

class WellnessAccuracyScreen extends StatefulWidget {
  const WellnessAccuracyScreen({super.key});

  @override
  State<WellnessAccuracyScreen> createState() => _WellnessAccuracyScreenState();
}

class _WellnessAccuracyScreenState extends State<WellnessAccuracyScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccuracy();
  }

  Future<void> _fetchAccuracy() async {
    try {
      final data = await _service.getAccuracy();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Accuracy Level', style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainLevelCard(),
                  const SizedBox(height: 40),
                  const Text('Why this accuracy?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: FemFlowColors.textPrimary)),
                  const SizedBox(height: 16),
                  const Text(
                    'Your accuracy is calculated based on how consistently you log your daily check-ins, cycles, symptoms, and wellness checks.',
                    style: TextStyle(color: FemFlowColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ...(_data!['reasons'] as List).map((r) => _buildReasonRow(r, true)),
                  const SizedBox(height: 40),
                  _buildActionCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMainLevelCard() {
    final level = _data!['accuracy_level'];
    final score = _data!['accuracy_score'];
    final color = _getAccuracyColor(level);

    return AppCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text('FemFlow Accuracy Level', style: TextStyle(fontSize: 16, color: FemFlowColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 16,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    level.toString().toUpperCase(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'High accuracy helps FemAI provide deeper insights tailored to your body patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: FemFlowColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonRow(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: FemFlowColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return AppCard(
      color: FemFlowColors.primary.withValues(alpha: 0.05),
      border: const BorderSide(color: FemFlowColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next Best Action', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary, fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            _data!['next_best_action'] ?? 'Complete a Quick Body & Mind Check today.',
            style: const TextStyle(fontSize: 15, color: FemFlowColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(dynamic level) {
    switch (level.toString().toLowerCase()) {
      case 'high': return Colors.green;
      case 'medium': return Colors.orange;
      default: return Colors.red;
    }
  }
}
