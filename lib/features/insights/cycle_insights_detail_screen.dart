import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/insights_service.dart';

class CycleInsightsDetailScreen extends StatefulWidget {
  const CycleInsightsDetailScreen({super.key});

  @override
  State<CycleInsightsDetailScreen> createState() => _CycleInsightsDetailScreenState();
}

class _CycleInsightsDetailScreenState extends State<CycleInsightsDetailScreen> {
  final InsightsService _service = InsightsService();
  bool _isLoading = true;
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _trends;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getOverview(),
        _service.getTrends('6_months'),
        _service.getHistory(),
      ]);
      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _trends = results[1] as Map<String, dynamic>;
        _history = results[2] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Cycle Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCycleSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTrendChart('Cycle Length Trend', _trends?['cycle_length_trend'] as List? ?? [], FemLyraColors.ovulation),
                  const SizedBox(height: 24),
                  _buildTrendChart('Period Length Trend', _trends?['period_length_trend'] as List? ?? [], FemLyraColors.period),
                  const SizedBox(height: 24),
                  _buildHistoryTable(),
                  const SizedBox(height: 24),
                  _buildAIRecommendation(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCycleSummaryCards() {
    final cycle = _overview?['cycle_summary'] ?? {};
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Regularity',
            (cycle['cycle_regularity'] ?? '--').toString().toUpperCase(),
            Icons.sync,
            FemLyraColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Confidence',
            (cycle['prediction_confidence'] ?? '--').toString().toUpperCase(),
            Icons.verified_user_outlined,
            FemLyraColors.ovulation,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
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
            height: 150,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < trend.length) {
                          return Text(trend[value.toInt()]['month'] ?? '', style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: trend.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['value'] as num).toDouble(),
                        color: color,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Last 6 Cycles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.take(6).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _history[index];
              final start = DateTime.parse(item['period_start_date']);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(start), style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Text('Period Start', style: TextStyle(fontSize: 11, color: FemLyraColors.textMuted)),
                        ],
                      ),
                    ),
                    _buildTableItem('${item['cycle_length'] ?? '--'} d', 'Cycle'),
                    const SizedBox(width: 24),
                    _buildTableItem('${item['period_length'] ?? '--'} d', 'Period'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: FemLyraColors.textMuted)),
      ],
    );
  }

  Widget _buildAIRecommendation() {
    return AppCard(
      color: FemLyraColors.lavender.withValues(alpha: 0.2),
      border: const BorderSide(color: FemLyraColors.lavender),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          _overview?['ai_recommendation'] ?? 'Maintain consistent sleep and logging to improve predictions.',
          style: const TextStyle(fontSize: 14, color: FemLyraColors.textSecondary, height: 1.5),
        ),
      ),
    );
  }
}
