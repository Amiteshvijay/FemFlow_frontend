import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'models/wellness_score_models.dart';

class WeeklyTrendScreen extends StatelessWidget {
  final WeeklyWellnessScore data;
  const WeeklyTrendScreen({super.key, required this.data});

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
        title: const Text(
          'Weekly Trend',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildChartCard(),
            const SizedBox(height: 24),
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildDailyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wellness Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.trend.map((t) => _buildBar(t)).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Your score improved on days with better sleep and lower pain.',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(DailyTrend t) {
    double height = (t.score / 100) * 160;
    String day = DateFormat('E').format(DateTime.parse(t.date));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${t.score}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: height.clamp(10, 160),
          decoration: BoxDecoration(
            color: FemFlowColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
      ],
    );
  }

  Widget _buildStatsCard() {
    if (data.trend.isEmpty) return const SizedBox.shrink();
    
    final sorted = List<DailyTrend>.from(data.trend)..sort((a, b) => a.score.compareTo(b.score));
    final lowest = sorted.first;
    final highest = sorted.last;

    return Row(
      children: [
        Expanded(child: _buildStatItem('Best Day', '${highest.score}', Icons.trending_up, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Lowest Day', '${lowest.score}', Icons.trending_down, Colors.red)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDailyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Daily Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...data.trend.reversed.map((t) => _buildDailyItem(t)),
      ],
    );
  }

  Widget _buildDailyItem(DailyTrend t) {
    DateTime date = DateTime.parse(t.date);
    String formattedDate = DateFormat('MMMM dd, EEEE').format(date);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate, style: const TextStyle(color: FemFlowColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: FemFlowColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${t.score}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
