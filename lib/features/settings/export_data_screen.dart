import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/login_screen.dart';
import 'data/settings_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final _settingsService = SettingsService();
  bool _isLoading = false;

  Future<void> _handleExport() async {
    final appLock = context.read<AppLockService>();
    setState(() => _isLoading = true);
    try {
      appLock.setTrustedExternalFlowActive(true);
      final data = await _settingsService.exportData();
      final jsonString = jsonEncode(data);
      
      // Share the data as a file
      final XFile xFile = XFile.fromData(
        utf8.encode(jsonString),
        mimeType: 'application/json',
        name: 'FemLyra_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      
      await Share.shareXFiles([xFile], text: 'My FemLyra Data Backup');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export completed')),
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _handleUnauthorized();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export data')),
      );
    } finally {
      appLock.setTrustedExternalFlowActive(false);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleUnauthorized() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login again')),
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
        title: const Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  const Icon(Icons.file_download_outlined, size: 48, color: FemLyraColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Export your cycle history, health logs, and chat data into a secure JSON file for backup or portability.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FemLyraColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Export & Share JSON',
              isLoading: _isLoading,
              onPressed: _handleExport,
            ),
            const SizedBox(height: 20),
            const Text(
              'Your data is processed locally on your device and shared securely.',
              style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
