import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/security/app_lock_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/login_screen.dart';
import 'data/settings_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _settingsService = SettingsService();
  String _lastBackup = 'Loading...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBackupStatus();
  }

  Future<void> _fetchBackupStatus() async {
    try {
      final status = await _settingsService.getBackupStatus();
      if (!mounted) return;
      setState(() {
        if (status['last_backup'] != null) {
          final date = DateTime.parse(status['last_backup']);
          _lastBackup = DateFormat('d MMM yyyy, hh:mm a').format(date.toLocal());
        } else {
          _lastBackup = 'Never';
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _handleUnauthorized();
        return;
      }
      setState(() => _lastBackup = 'Error loading status');
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    try {
      final result = await _settingsService.startBackup();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup timestamp updated')),
      );
      
      if (result['last_backup'] != null) {
        final date = DateTime.parse(result['last_backup']);
        setState(() {
          _lastBackup = DateFormat('d MMM yyyy, hh:mm a').format(date.toLocal());
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _handleUnauthorized();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update backup status')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    final appLock = context.read<AppLockService>();
    try {
      appLock.setTrustedExternalFlowActive(true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        final response = await _settingsService.importData(data);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Data restored successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: ${e.toString()}')),
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
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Backup & Restore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 48, color: FemFlowColors.primary),
                  const SizedBox(height: 16),
                  Text('Last cloud sync: $_lastBackup', style: const TextStyle(color: FemFlowColors.textSecondary)),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Sync Status Now',
                    isLoading: _isLoading,
                    onPressed: _handleBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual Restore',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload a previously exported FemFlow JSON file to restore all your cycle history and health logs. WARNING: This will overwrite current data.',
                    style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleRestore,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: FemFlowColors.primary),
                      foregroundColor: FemFlowColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Choose JSON File to Restore'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
