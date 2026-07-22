import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/health_report_model.dart';
import '../data/report_service.dart';

class HealthReportPreviewScreen extends StatefulWidget {
  final HealthReport report;
  final String startDate;
  final String endDate;
  final bool includeRawLogs;

  const HealthReportPreviewScreen({
    super.key,
    required this.report,
    required this.startDate,
    required this.endDate,
    this.includeRawLogs = false,
  });

  @override
  State<HealthReportPreviewScreen> createState() => _HealthReportPreviewScreenState();
}

class _HealthReportPreviewScreenState extends State<HealthReportPreviewScreen> {
  final ReportService _service = ReportService();
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      final file = await _service.downloadHealthReportPdf(
        startDate: widget.startDate,
        endDate: widget.endDate,
        includeRawLogs: widget.includeRawLogs,
      );

      if (file != null && mounted) {
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isDownloading = true);
    try {
      final file = await _service.downloadHealthReportPdf(
        startDate: widget.startDate,
        endDate: widget.endDate,
        includeRawLogs: widget.includeRawLogs,
      );

      if (file != null && mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'My FemLyra Health Report');
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
        title: const Text('Health Report Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildReadyCard(),
            const SizedBox(height: 24),
            _buildPreviewSection('Personal Information', [
              _buildRow('Full Name', widget.report.personalInfo.fullName),
              _buildRow('BMI Status', widget.report.personalInfo.bmi),
              _buildRow('Location', widget.report.personalInfo.location),
            ]),
            const SizedBox(height: 16),
            _buildPreviewSection('Cycle Summary', [
              _buildRow('Total Cycles', widget.report.cycleSummary.totalCycles.toString()),
              _buildRow('Avg Length', widget.report.cycleSummary.avgCycleLength),
              _buildRow('Current Phase', widget.report.cycleSummary.currentPhase),
            ]),
            const SizedBox(height: 16),
            _buildPreviewSection('Doctor Summary', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.report.doctorSummary,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: FemFlowColors.textSecondary),
                ),
              ),
            ]),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Download PDF',
              isLoading: _isDownloading,
              onPressed: _handleDownload,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isDownloading ? null : _handleShare,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: FemFlowColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Share PDF', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyCard() {
    return AppCard(
      color: Colors.green.withValues(alpha: 0.1),
      border: const BorderSide(color: Colors.green, width: 0.5),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Generated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('A professional A4 PDF is ready for you.', style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, List<Widget> rows) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FemFlowColors.primary)),
          const Divider(height: 24),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
