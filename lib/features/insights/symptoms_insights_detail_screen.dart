import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/insights_service.dart';

class SymptomsInsightsDetailScreen extends StatefulWidget {
  const SymptomsInsightsDetailScreen({super.key});

  @override
  State<SymptomsInsightsDetailScreen> createState() => _SymptomsInsightsDetailScreenState();
}

class _SymptomsInsightsDetailScreenState extends State<SymptomsInsightsDetailScreen> {
  final InsightsService _service = InsightsService();
  bool _isLoading = true;
  String _selectedRange = '30_days';
  Map<String, dynamic>? _symptomsData;
  Map<String, dynamic>? _trendsData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getSymptomsInsights(),
        _service.getTrends(_selectedRange),
      ]);
      setState(() {
        _symptomsData = results[0];
        _trendsData = results[1];
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
        title: const Text('Symptoms Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRangeSelector(),
                  const SizedBox(height: 24),
                  _buildTopSymptomsChart(),
                  const SizedBox(height: 24),
                  _buildTrendChart(),
                  const SizedBox(height: 24),
                  _buildAIInsight(),
                  const SizedBox(height: 24),
                  _buildSafetyNote(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildRangeSelector() {
    final ranges = {
      '7_days': '7 Days',
      '30_days': '30 Days',
      '3_months': '3 Months',
      '6_months': '6 Months',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ranges.entries.map((e) {
          final isSelected = _selectedRange == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedRange = e.key);
                _fetchData();
              },
              selectedColor: FemFlowColors.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : FemFlowColors.border)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopSymptomsChart() {
    final top = _symptomsData?['top_symptoms'] as List? ?? [];
    if (top.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Symptoms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ...top.map((s) => _buildSymptomProgress(s['name'], s['percentage'] / 100)),
        ],
      ),
    );
  }

  Widget _buildSymptomProgress(String name, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name[0].toUpperCase() + name.substring(1), style: const TextStyle(fontSize: 14)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(FemFlowColors.primary),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final trend = _trendsData?['symptom_trend'] as List? ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Intensity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) {
                      // Sum all symptom flags for day intensity
                      double intensity = 0;
                      e.value.forEach((k, v) { if (k != 'date') intensity += v; });
                      return FlSpot(e.key.toDouble(), intensity);
                    }).toList(),
                    isCurved: true,
                    color: FemFlowColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: FemFlowColors.primary.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsight() {
    return AppCard(
      color: FemFlowColors.lavender.withValues(alpha: 0.2),
      border: const BorderSide(color: FemFlowColors.lavender),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: FemFlowColors.aiWellness, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('AI Insight', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
                SizedBox(height: 8),
                Text(
                  'Cramps and fatigue often peak 2 days before your period. Prioritize iron-rich foods and light rest during this window.',
                  style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.5),
                ),
              ],
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
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: FemFlowColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'If symptoms are severe, unusual, or affect daily life, please consult a qualified doctor.',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
