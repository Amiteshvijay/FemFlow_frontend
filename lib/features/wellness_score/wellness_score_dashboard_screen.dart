import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_score_models.dart';
import 'daily_checkin_screen.dart';
import 'score_breakdown_screen.dart';
import 'weekly_trend_screen.dart';
import 'wellness_checks_screen.dart';
import 'monthly_wellness_report_screen.dart';
import '../../core/network/api_client.dart';
import '../premium/premium_feature_preview_screen.dart';

class WellnessScoreDashboardScreen extends StatefulWidget {
  const WellnessScoreDashboardScreen({super.key});

  @override
  State<WellnessScoreDashboardScreen> createState() => _WellnessScoreDashboardScreenState();
}

class _WellnessScoreDashboardScreenState extends State<WellnessScoreDashboardScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  WeeklyWellnessScore? _weeklyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getWeeklyScore();
      if (mounted) {
        setState(() {
          _weeklyData = data;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.detailCode == 'premium_required' || e.statusCode == 403) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'wellness_score')),
          );
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text(
          'FemFlow Wellness Score',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: FemFlowColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMainScoreCard(),
                    const SizedBox(height: 24),
                    _buildAISummaryCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    _buildDisclaimer(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainScoreCard() {
    if (_weeklyData == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FemFlowColors.primary, FemFlowColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FemFlowColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Weekly Score',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: _weeklyData!.score / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${_weeklyData!.score}',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '/ 100',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _weeklyData?.status ?? 'N/A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on last 7 days',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummaryCard() {
    if (_weeklyData == null) return const SizedBox.shrink();

    return AppCard(
      color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Reflection',
            style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness),
          ),
          const SizedBox(height: 8),
          Text(
            _weeklyData?.aiSummary ?? 'No summary available yet.',
            style: const TextStyle(color: FemFlowColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          'Daily Check-in',
          Icons.edit_note,
          FemFlowColors.primary,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCheckinScreen())).then((_) => _loadData()),
        ),
        _buildActionCard(
          'Score Breakdown',
          Icons.analytics_outlined,
          Colors.blue,
          _weeklyData == null 
              ? () {} 
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScoreBreakdownScreen(data: _weeklyData!))),
        ),
        _buildActionCard(
          'Weekly Trend',
          Icons.show_chart,
          Colors.orange,
          _weeklyData == null 
              ? () {} 
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyTrendScreen(data: _weeklyData!))),
        ),
        _buildActionCard(
          'Wellness Checks',
          Icons.assignment_turned_in_outlined,
          FemFlowColors.ovulation,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessChecksScreen())).then((_) => _loadData()),
        ),
        _buildActionCard(
          'Monthly Report',
          Icons.calendar_month_outlined,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyWellnessReportScreen())),
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FemFlowColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: FemFlowColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This score is an educational wellness indicator and not a medical diagnosis.',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
