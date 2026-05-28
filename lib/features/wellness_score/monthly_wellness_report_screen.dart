import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_io/io.dart' as io;
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_score_models.dart';
import '../subscriptions/providers/subscription_provider.dart';
import '../subscriptions/widgets/premium_feature_locked_widget.dart';
import 'package:provider/provider.dart';

class MonthlyWellnessReportScreen extends StatefulWidget {
  const MonthlyWellnessReportScreen({super.key});

  @override
  State<MonthlyWellnessReportScreen> createState() => _MonthlyWellnessReportScreenState();
}

class _MonthlyWellnessReportScreenState extends State<MonthlyWellnessReportScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  MonthlyWellnessReport? _report;
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final data = await _service.getMonthlyReport(month: now.month, year: now.year);
      setState(() {
        _report = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExportPDF() async {
    setState(() => _isDownloading = true);
    try {
      final now = DateTime.now();
      final bytes = await _service.downloadMonthlyReport(now.month, now.year);
      final fileName = 'FemFlow_Wellness_Report_${now.year}_${now.month}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report saved as $fileName'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFilex.open(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
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
          'Monthly Wellness Report',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscription, child) {
          if (!subscription.isPremium) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: PremiumFeatureLockedWidget(
                  title: 'Monthly Wellness Report',
                  description: 'Get deep insights into your health patterns with our monthly AI reflection and data-driven trends.',
                  icon: Icons.assignment_outlined,
                ),
              ),
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator(color: FemFlowColors.primary));
          }
          
          if (_report == null) {
            return const Center(child: Text('No report data available yet.'));
          }

          return RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMonthlySummary(),
                  const SizedBox(height: 24),
                  _buildInsightsList(),
                  const SizedBox(height: 32),
                  _buildFemAIReflection(),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: 'Export Full Report (PDF)',
                    isLoading: _isDownloading,
                    onPressed: _isDownloading ? null : _handleExportPDF,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return AppCard(
      color: FemFlowColors.primary.withValues(alpha: 0.05),
      child: Column(
        children: [
          Text('${_report!.monthName} ${_report!.year} Average', style: const TextStyle(color: FemFlowColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '${_report!.avgScore}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
          ),
          Text(_report!.statusLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Best Day', _report!.bestDay),
              _buildMiniStat('Top Symptom', _report!.topSymptom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
      ],
    );
  }

  Widget _buildInsightsList() {
    return Column(
      children: [
        _buildInsightItem('Best Area', _report!.bestArea, Icons.bolt, Colors.green),
        _buildInsightItem('Needs Attention', _report!.needsAttention, Icons.bedtime_outlined, Colors.orange),
        _buildInsightItem('Cycle Pattern', _report!.cyclePattern, Icons.water_drop_outlined, FemFlowColors.period),
      ],
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                  Text(
                    value, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFemAIReflection() {
    return AppCard(
      color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FemAI Monthly Reflection', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
          const SizedBox(height: 12),
          Text(
            '“${_report!.aiReflection}”',
            style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
