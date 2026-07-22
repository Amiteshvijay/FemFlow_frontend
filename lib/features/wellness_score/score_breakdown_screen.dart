import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'models/wellness_score_models.dart';

class ScoreBreakdownScreen extends StatelessWidget {
  final WeeklyWellnessScore data;
  const ScoreBreakdownScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Score Breakdown',
          style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOverallCard(),
            const SizedBox(height: 24),
            _buildSubScoresList(),
            const SizedBox(height: 32),
            _buildRecommendationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallCard() {
    return AppCard(
      color: FemLyraColors.primary.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Score', style: TextStyle(color: FemLyraColors.textSecondary)),
              const SizedBox(height: 4),
              Text(data.status, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
            ],
          ),
          Text(
            '${data.score}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubScoresList() {
    final subScores = data.subScores;
    return Column(
      children: subScores.entries.map((e) => _buildSubScoreCard(e.key, e.value)).toList(),
    );
  }

  Widget _buildSubScoreCard(String key, int score) {
    String label = '${key[0].toUpperCase()}${key.substring(1)} Balance';
    String explanation = _getExplanation(key, score);
    Color color = _getColor(score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$score', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _getExplanation(String key, int score) {
    if (score >= 85) return 'Your $key levels are excellently balanced.';
    if (score >= 70) return 'Your $key levels are well managed.';
    if (score >= 55) return 'Your $key levels are slightly affecting your balance.';
    return 'Your $key levels are significantly impacting your wellness score.';
  }

  Color _getColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecommendationCard() {
    return AppCard(
      color: Colors.blue.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Recommendation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Try consistent sleep timing and gentle rest before your period phase to improve your overall balance.',
            style: TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
