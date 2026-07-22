import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/security/app_lock_service.dart';
import '../cycles/data/cycle_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final CycleService _cycleService = CycleService();
  String _dateRange = 'complete'; // complete, custom, financial_year
  DateTime? _startDate;
  DateTime? _endDate;
  String _format = 'pdf'; // pdf, csv

  final Map<String, bool> _categories = {
    'Cycle Logs': true,
    'Symptoms & Mood': true,
    'Wellness Scores': true,
    'Doctor Bookings': true,
    'Test Results': true,
    'Health Vault': true,
    'Pill Reminders': true,
  };

  bool _isExporting = false;
  List<CycleLog> _fetchedCycleLogs = [];
  List<SymptomLog> _fetchedSymptomLogs = [];

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: FemLyraColors.primary,
              onPrimary: Colors.white,
              onSurface: FemLyraColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateRange = 'custom';
      });
    }
  }

  void _handleExport() async {
    setState(() => _isExporting = true);
    
    try {
      // 1. Fetch real data from services
      if (_categories['Cycle Logs'] == true) {
        _fetchedCycleLogs = await _cycleService.getCycleLogs();
      }
      if (_categories['Symptoms & Mood'] == true) {
        _fetchedSymptomLogs = await _cycleService.getSymptomLogs();
      }

      // Simulate some processing time for other categories
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isExporting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _downloadReport() async {
    final appLock = context.read<AppLockService>();
    appLock.setTrustedExternalFlowActive(true);
    
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'FemLyra_Health_Report_$timestamp.$_format';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (_format == 'pdf') {
        // GENERATE REAL PDF
        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text('FemLyra HEALTH REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Generated on: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}'),
                pw.Text('Date Range: ${_dateRange.toUpperCase()}'),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                if (_categories['Cycle Logs'] == true && _fetchedCycleLogs.isNotEmpty) ...[
                  pw.Text('Cycle Logs', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    data: [
                      ['Start Date', 'End Date', 'Status', 'Flow'],
                      ..._fetchedCycleLogs.map((log) => [
                        DateFormat('MMM d, yyyy').format(log.periodStartDate),
                        log.periodEndDate != null ? DateFormat('MMM d, yyyy').format(log.periodEndDate!) : 'In Progress',
                        log.status,
                        log.flow ?? 'Medium',
                      ]),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],

                if (_categories['Symptoms & Mood'] == true && _fetchedSymptomLogs.isNotEmpty) ...[
                  pw.Text('Symptoms & Mood Trends', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    data: [
                      ['Date', 'Mood', 'Symptoms', 'Pain'],
                      ..._fetchedSymptomLogs.take(15).map((log) => [
                        DateFormat('MMM d').format(log.date),
                        log.mood ?? 'N/A',
                        log.symptoms.take(2).join(', '),
                        log.painLevel?.toString() ?? '-',
                      ]),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],

                pw.Divider(),
                pw.Center(child: pw.Text('End of Report. Your data is private and secure.', style: const pw.TextStyle(fontSize: 10))),
              ];
            },
          ),
        );

        await file.writeAsBytes(await pdf.save());
      } else {
        // GENERATE REAL CSV
        final StringBuffer csvBuffer = StringBuffer();
        
        // Metadata
        csvBuffer.writeln('FemLyra HEALTH REPORT');
        csvBuffer.writeln('Generated on,${DateTime.now()}');
        csvBuffer.writeln('Range,$_dateRange');
        csvBuffer.writeln('');

        // Cycle Logs Section
        if (_categories['Cycle Logs'] == true && _fetchedCycleLogs.isNotEmpty) {
          csvBuffer.writeln('--- CYCLE LOGS ---');
          csvBuffer.writeln('Start Date,End Date,Status,Flow,Notes');
          for (var log in _fetchedCycleLogs) {
            csvBuffer.writeln('${log.periodStartDate.toIso8601String().split('T')[0]},'
                '${log.periodEndDate?.toIso8601String().split('T')[0] ?? "In Progress"},'
                '${log.status},'
                '${log.flow ?? "Medium"},'
                '"${log.notes ?? ""}"');
          }
          csvBuffer.writeln('');
        }

        // Symptoms Section
        if (_categories['Symptoms & Mood'] == true && _fetchedSymptomLogs.isNotEmpty) {
          csvBuffer.writeln('--- SYMPTOMS & MOOD ---');
          csvBuffer.writeln('Date,Mood,Pain Level,Energy,Symptoms,Notes');
          for (var log in _fetchedSymptomLogs) {
            csvBuffer.writeln('${log.date.toIso8601String().split('T')[0]},'
                '${log.mood ?? ""},'
                '${log.painLevel ?? ""},'
                '${log.energyLevel ?? ""},'
                '"${log.symptoms.join(", ")}",'
                '"${log.notes ?? ""}"');
          }
        }

        await file.writeAsString(csvBuffer.toString());
      }
      
      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath)], 
          text: 'My FemLyra Health Report',
          subject: 'Health Report'
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        appLock.setTrustedExternalFlowActive(false);
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Export Ready', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Your health data report ($_format) has been generated and is ready for download.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _downloadReport();
            },
            child: const Text('Download Now', style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Export My Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Select Period'),
            _buildDateRangeSelector(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Data Categories'),
            _buildCategorySelector(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Export Format'),
            _buildFormatSelector(),
            const SizedBox(height: 48),
            
            PrimaryButton(
              label: _isExporting ? 'Generating Report...' : 'Generate Health Report',
              isLoading: _isExporting,
              onPressed: _isExporting ? null : _handleExport,
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Reports may take a few moments to generate.',
                style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: RadioGroup<String>(
        groupValue: _dateRange,
        onChanged: (val) => setState(() => _dateRange = val!),
        child: Column(
          children: [
            RadioListTile<String>(
              title: const Text('Complete History'),
              value: 'complete',
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: const Text('Last Financial Year'),
              value: 'financial_year',
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Custom Period'),
              subtitle: _startDate != null && _endDate != null
                  ? Text('${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}')
                  : const Text('Select start and end dates'),
              trailing: Icon(Icons.calendar_today_outlined, 
                color: _dateRange == 'custom' ? FemLyraColors.primary : FemLyraColors.textMuted, size: 20),
              onTap: () => _selectDateRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: _categories.keys.map((cat) {
          return CheckboxListTile(
            title: Text(cat),
            value: _categories[cat],
            activeColor: FemLyraColors.primary,
            onChanged: (val) => setState(() => _categories[cat] = val!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: [
        _buildFormatOption('PDF Document', 'pdf', Icons.picture_as_pdf_outlined),
        const SizedBox(width: 16),
        _buildFormatOption('CSV Spreadsheet', 'csv', Icons.table_chart_outlined),
      ],
    );
  }

  Widget _buildFormatOption(String label, String value, IconData icon) {
    final isSelected = _format == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _format = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? FemLyraColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? FemLyraColors.primary : FemLyraColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? FemLyraColors.primary : FemLyraColors.textMuted),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? FemLyraColors.primary : FemLyraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
