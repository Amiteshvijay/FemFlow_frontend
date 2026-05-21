import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/insights_service.dart';
import 'symptoms_insights_detail_screen.dart';
import 'cycle_insights_detail_screen.dart';
import 'mood_insights_detail_screen.dart';
import 'pain_energy_detail_screen.dart';
import '../../core/network/api_client.dart';
import '../premium/premium_guard.dart';
import '../subscriptions/screens/premium_plan_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InsightsService _insightsService = InsightsService();
  bool _isLoading = true;
  Map<String, dynamic>? _overviewData;
  Map<String, dynamic>? _trendsData;
  List<dynamic> _historyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {}); // Rebuild to show different tab content
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _insightsService.getOverview(),
        _insightsService.getTrends('30_days'),
        _insightsService.getHistory(),
      ]);

      if (mounted) {
        setState(() {
          _overviewData = results[0] as Map<String, dynamic>?;
          _trendsData = results[1] as Map<String, dynamic>?;
          _historyData = results[2] as List<dynamic>;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.detailCode == 'premium_required' || e.statusCode == 403) {
          // If this tab is opened and API returns 403, we show preview
          // Though the main_shell already gates it, this is a double safety.
          setState(() {
             _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: FemFlowColors.primary,
                child: CustomScrollView(
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Insights',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      sliver: SliverToBoxAdapter(
                        child: TabBar(
                          controller: _tabController,
                          labelColor: FemFlowColors.primary,
                          unselectedLabelColor: FemFlowColors.textMuted,
                          indicatorColor: FemFlowColors.primary,
                          tabs: const [
                            Tab(text: 'Cycles'),
                            Tab(text: 'Logs'),
                            Tab(text: 'Timeline'),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(_buildTabContent()),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildCyclesTab();
      case 1:
        return _buildLogsTab();
      case 2:
        return _buildTimelineTab();
      default:
        return [];
    }
  }

  List<Widget> _buildCyclesTab() {
    final isPremium = PremiumGuard.isPremium(context);
    final cycle = _overviewData?['cycle_summary'] ?? {};
    final cycleTrendRaw = _trendsData?['cycle_length_trend'] as List? ?? [];
    
    // For free users, show only last 2 months of trend
    final cycleTrend = (isPremium || cycleTrendRaw.length <= 2) 
        ? cycleTrendRaw 
        : cycleTrendRaw.sublist(cycleTrendRaw.length - 2);

    return [
      _buildPremiumMetricCard(
        title: 'Cycle Length',
        value: '${cycle['average_cycle_length'] ?? '--'} days',
        subtitle: (cycle['cycle_regularity'] ?? 'Unknown').toString().toUpperCase(),
        color: FemFlowColors.primary,
      ),
      const SizedBox(height: 16),
      _buildPremiumMetricCard(
        title: 'Period Length',
        value: '${cycle['average_period_length'] ?? '--'} days',
        subtitle: 'Prediction Confidence: ${(cycle['prediction_confidence'] ?? 'Low').toString().toUpperCase()}',
        color: FemFlowColors.period,
      ),
      const SizedBox(height: 20),
      _buildSectionHeader(
        'Cycle Length Trend', 
        () => PremiumGuard.openPremiumFeature(
          context: context, 
          featureKey: 'cycle_insights', 
          premiumScreen: const CycleInsightsDetailScreen()
        ),
        isPremium: isPremium,
      ),
      const SizedBox(height: 12),
      SizedBox(height: 150, child: _buildBarChart(cycleTrend)),
      if (!isPremium && cycleTrendRaw.length > 2)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _buildInlinePremiumPreview(
            'Unlock full cycle history and 12-month trends with Premium.',
          ),
        ),
      const SizedBox(height: 20),
      const Text('Recent History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (_historyData.isEmpty)
        const Text('No history yet.', style: TextStyle(color: FemFlowColors.textMuted))
      else
        ..._historyData.take(isPremium ? 3 : 2).map((item) => _buildHistoryStrip(item)),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildLogsTab() {
    final isPremium = PremiumGuard.isPremium(context);
    final symptom = _overviewData?['symptom_summary'] ?? {};
    final topSymptomsRaw = symptom['top_symptoms'] as List? ?? [];
    final painTrend = _trendsData?['pain_level_trend'] as List? ?? [];
    final energyTrend = _trendsData?['energy_level_trend'] as List? ?? [];

    final topSymptoms = (isPremium || topSymptomsRaw.length <= 2)
        ? topSymptomsRaw
        : topSymptomsRaw.take(2).toList();

    return [
      _buildSectionHeader(
        'Symptoms Frequency', 
        () => PremiumGuard.openPremiumFeature(
          context: context, 
          featureKey: 'cycle_insights', 
          premiumScreen: const SymptomsInsightsDetailScreen()
        ),
        isPremium: isPremium,
      ),
      const SizedBox(height: 12),
      if (topSymptoms.isEmpty)
        const Text('No symptoms logged yet.', style: TextStyle(color: FemFlowColors.textMuted))
      else
        ...topSymptoms.map((s) => _buildSymptomRow(s['name'], s['count'])),
      
      if (!isPremium) ...[
        const SizedBox(height: 24),
        _buildAdvancedLogsPreview(),
      ] else ...[
        const SizedBox(height: 20),
        _buildSectionHeader('Mood Pattern', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodInsightsDetailScreen()))),
        const SizedBox(height: 12),
        const Text('Mood changes seem more frequent near your period phase.', style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
        const SizedBox(height: 20),
        _buildSectionHeader('Pain Trend', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PainEnergyDetailScreen()))),
        const SizedBox(height: 12),
        SizedBox(height: 120, child: _buildLineChart(painTrend, Colors.red)),
        const SizedBox(height: 20),
        _buildSectionHeader('Energy Trend', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PainEnergyDetailScreen()))),
        const SizedBox(height: 12),
        SizedBox(height: 120, child: _buildLineChart(energyTrend, Colors.blue)),
      ],
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildTimelineTab() {
    final isPremium = PremiumGuard.isPremium(context);
    if (_historyData.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('No cycle history yet.', style: TextStyle(color: FemFlowColors.textMuted)),
          ),
        )
      ];
    }

    final historyToShow = isPremium ? _historyData : _historyData.take(2).toList();

    return [
      const Text('Cycle History List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...historyToShow.map((item) => _buildTimelineItem(item)),
      if (!isPremium && _historyData.length > 2)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _buildInlinePremiumPreview(
            'See your complete cycle history and patterns over time with Premium.',
          ),
        ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildAdvancedLogsPreview() {
    return AppCard(
      onTap: () => PremiumGuard.openPremiumFeature(
        context: context, 
        featureKey: 'cycle_insights', 
        premiumScreen: const InsightsScreen()
      ),
      color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Advanced Health Logs',
                style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Analyze mood patterns, pain levels, and energy trends across your entire cycle.',
            style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Unlock Mood & Pain Analytics >',
                style: TextStyle(color: FemFlowColors.aiWellness, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlinePremiumPreview(String message) {
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPlanScreen())),
      color: Colors.white,
      border: BorderSide(color: FemFlowColors.primary.withValues(alpha: 0.2)),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: FemFlowColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'UPGRADE',
            style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll, {bool isPremium = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            isPremium ? 'View All' : 'Unlock All >', 
            style: const TextStyle(color: FemFlowColors.primary, fontSize: 13, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumMetricCard({required String title, required String value, required String subtitle, required Color color}) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildHistoryStrip(dynamic item) {
    final start = DateTime.parse(item['period_start_date']);
    final length = item['cycle_length'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FemFlowColors.blushMist,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('MMMM yyyy').format(start), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(length != null ? '$length days' : '-- days', style: const TextStyle(color: FemFlowColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(dynamic item) {
    final start = DateTime.parse(item['period_start_date']);
    final endStr = item['period_end_date'];
    final end = endStr != null ? DateTime.parse(endStr) : null;
    final cycleLength = item['cycle_length'];
    final periodLength = item['period_length'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMM d').format(start)} - ${end != null ? DateFormat('MMM d, yyyy').format(end) : 'In Progress'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricSubItem('Period', periodLength != null ? '$periodLength days' : '--'),
                _buildMetricSubItem('Cycle', cycleLength != null ? '$cycleLength days' : '--'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSubItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSymptomRow(String name, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 14)),
          Text('$count times', style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> trend) {
    if (trend.isEmpty) return const Center(child: Text('No data yet'));
    return BarChart(
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
        barGroups: trend.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['value'] as num).toDouble(), color: FemFlowColors.ovulation, width: 14)])).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> trend, Color color) {
    if (trend.isEmpty) return const Center(child: Text('No data yet'));
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
