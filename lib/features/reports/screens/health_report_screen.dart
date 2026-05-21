import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/report_service.dart';
import 'health_report_preview_screen.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  final ReportService _service = ReportService();
  String _rangeKey = '3_months';
  DateTime? _customStart;
  DateTime? _customEnd;

  bool _includeRawLogs = true;
  bool _includeVault = false;
  bool _includeAI = true;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Export Health Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Select Period'),
            _buildRangeSelector(),
            const SizedBox(height: 32),
            _buildSectionHeader('Include Sections'),
            _buildInclusions(),
            const SizedBox(height: 48),
            PrimaryButton(
              label: _isGenerating ? 'Generating Report...' : 'Generate Health Report',
              isLoading: _isGenerating,
              onPressed: _isGenerating ? null : _handleGenerate,
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Professional A4 PDF summary for your doctor.',
                style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: RadioGroup<String>(
        groupValue: _rangeKey,
        onChanged: (val) => setState(() {
          _rangeKey = val!;
          _customStart = null;
        }),
        child: Column(
          children: [
            RadioListTile<String>(
              title: const Text('Last 1 Month'),
              value: '1_month',
              activeColor: FemFlowColors.primary,
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: const Text('Last 3 Months'),
              value: '3_months',
              activeColor: FemFlowColors.primary,
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: const Text('Last 6 Months'),
              value: '6_months',
              activeColor: FemFlowColors.primary,
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Custom Range'),
              trailing: const Icon(Icons.calendar_today_outlined, size: 20),
              onTap: _pickCustomRange,
              subtitle: _customStart != null 
                ? Text('${DateFormat('d MMM').format(_customStart!)} - ${DateFormat('d MMM').format(_customEnd!)}')
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInclusions() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Append Raw Activity Logs'),
            subtitle: const Text('Detailed table of daily logs in appendix'),
            value: _includeRawLogs,
            activeColor: FemFlowColors.primary,
            onChanged: (val) => setState(() => _includeRawLogs = val!),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            title: const Text('Health Vault Summary'),
            subtitle: const Text('Metadata of uploaded documents'),
            value: _includeVault,
            activeColor: FemFlowColors.primary,
            onChanged: (val) => setState(() => _includeVault = val!),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            title: const Text('FemAI Priority Insights'),
            subtitle: const Text('Personalized wellness summary'),
            value: _includeAI,
            activeColor: FemFlowColors.primary,
            onChanged: (val) => setState(() => _includeAI = val!),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context, 
      firstDate: DateTime(2020), 
      lastDate: DateTime.now()
    );
    if (range != null) {
      setState(() {
        _customStart = range.start;
        _customEnd = range.end;
        _rangeKey = 'custom';
      });
    }
  }

  Future<void> _handleGenerate() async {
    setState(() => _isGenerating = true);
    
    // Calculate dates
    DateTime end = DateTime.now();
    DateTime start;
    
    if (_rangeKey == 'custom' && _customStart != null) {
      start = _customStart!;
      end = _customEnd!;
    } else {
      int months = _rangeKey == '1_month' ? 1 : (_rangeKey == '6_months' ? 6 : 3);
      start = end.subtract(Duration(days: 30 * months));
    }

    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    try {
      final report = await _service.getHealthReportJson(
        startDate: startStr, 
        endDate: endStr,
        includeRawLogs: _includeRawLogs
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HealthReportPreviewScreen(
            report: report, 
            startDate: startStr, 
            endDate: endStr,
            includeRawLogs: _includeRawLogs,
          ))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
