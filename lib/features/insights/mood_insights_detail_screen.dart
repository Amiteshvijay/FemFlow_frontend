import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/insights_service.dart';

class MoodInsightsDetailScreen extends StatefulWidget {
  const MoodInsightsDetailScreen({super.key});

  @override
  State<MoodInsightsDetailScreen> createState() => _MoodInsightsDetailScreenState();
}

class _MoodInsightsDetailScreenState extends State<MoodInsightsDetailScreen> {
  final InsightsService _service = InsightsService();
  bool _isLoading = true;
  Map<String, dynamic>? _moodData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMoodInsights();
      setState(() {
        _moodData = data;
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
        title: const Text('Mood Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMostCommonMoodCard(),
                  const SizedBox(height: 24),
                  _buildMoodDistributionChart(),
                  const SizedBox(height: 24),
                  _buildMoodTrendChart(),
                  const SizedBox(height: 24),
                  _buildAINote(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMostCommonMoodCard() {
    final dist = _moodData?['mood_distribution'] as List? ?? [];
    if (dist.isEmpty) return const SizedBox.shrink();

    final top = dist.reduce((a, b) => a['count'] > b['count'] ? a : b);

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FemFlowColors.aiWellness.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.sentiment_satisfied_alt, color: FemFlowColors.aiWellness, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Most Common Mood', style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
              Text(
                (top['mood'] ?? 'N/A').toString().toUpperCase(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionChart() {
    final dist = _moodData?['mood_distribution'] as List? ?? [];
    if (dist.isEmpty) return const SizedBox.shrink();

    final List<Color> colors = [
      FemFlowColors.primary,
      FemFlowColors.ovulation,
      FemFlowColors.aiWellness,
      FemFlowColors.fertileWindow,
      FemFlowColors.pmsCaution
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: dist.asMap().entries.map((e) {
                  return PieChartSectionData(
                    value: (e.value['count'] as num).toDouble(),
                    title: e.value['mood'],
                    radius: 20,
                    color: colors[e.key % colors.length],
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(dist, colors),
        ],
      ),
    );
  }

  Widget _buildLegend(List dist, List<Color> colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: dist.asMap().entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(e.value['mood'], style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMoodTrendChart() {
    final trend = _moodData?['mood_trend'] as List? ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    // Map moods to numeric for Y axis
    final moodMap = {"sad": 1, "tired": 2, "okay": 3, "happy": 4, "energetic": 5};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Cycle Pattern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) {
                      final val = moodMap[e.value['mood'].toString().toLowerCase()] ?? 3;
                      return FlSpot(e.key.toDouble(), val.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: FemFlowColors.aiWellness,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('Higher points indicate more positive moods', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: FemFlowColors.textMuted))),
        ],
      ),
    );
  }

  Widget _buildAINote() {
    return AppCard(
      color: FemFlowColors.lavender.withValues(alpha: 0.1),
      border: const BorderSide(color: FemFlowColors.lavender),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: FemFlowColors.aiWellness, size: 20),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Mood changes seem more frequent near your period days. This is a common pattern influenced by hormonal shifts.',
              style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
