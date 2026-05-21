import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/insights_service.dart';

class PainEnergyDetailScreen extends StatefulWidget {
  const PainEnergyDetailScreen({super.key});

  @override
  State<PainEnergyDetailScreen> createState() => _PainEnergyDetailScreenState();
}

class _PainEnergyDetailScreenState extends State<PainEnergyDetailScreen> {
  final InsightsService _service = InsightsService();
  bool _isLoading = true;
  Map<String, dynamic>? _trends;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getTrends('30_days');
      setState(() {
        _trends = data;
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
        title: const Text('Pain & Energy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  _buildTrendChart('Pain Level Trend', _trends?['pain_level_trend'] as List? ?? [], Colors.red),
                  const SizedBox(height: 24),
                  _buildTrendChart('Energy Level Trend', _trends?['energy_level_trend'] as List? ?? [], Colors.blue),
                  const SizedBox(height: 24),
                  _buildRecommendationCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTrendChart(String title, List trend, Color color) {
    if (trend.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.05)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('30 Day View', style: TextStyle(fontSize: 10, color: FemFlowColors.textMuted))),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final trend = _trends?['pain_level_trend'] as List? ?? [];
    bool highPain = trend.any((e) => (e['value'] as num) >= 8);

    return AppCard(
      color: (highPain ? Colors.red : Colors.green).withValues(alpha: 0.05),
      border: BorderSide(color: highPain ? Colors.red : Colors.green, width: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(highPain ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: highPain ? Colors.red : Colors.green),
              const SizedBox(width: 12),
              Text('Recommendation', style: TextStyle(fontWeight: FontWeight.bold, color: highPain ? Colors.red : Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            highPain 
              ? 'Severe pain level detected. Please consult a qualified doctor if this is unusual or affects your daily life.'
              : 'Your levels look stable. Gentle movement, hydration, and rest may help maintain your energy balance.',
            style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
