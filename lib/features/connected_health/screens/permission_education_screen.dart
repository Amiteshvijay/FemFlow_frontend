import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/health_integration_service.dart';

class PermissionEducationScreen extends StatefulWidget {
  const PermissionEducationScreen({super.key});

  @override
  State<PermissionEducationScreen> createState() => _PermissionEducationScreenState();
}

class _PermissionEducationScreenState extends State<PermissionEducationScreen> {
  final HealthIntegrationService _healthService = HealthIntegrationService();
  bool _isRequesting = false;

  Future<void> _handleConnect() async {
    setState(() => _isRequesting = true);
    try {
      final success = await _healthService.requestPermissions();
      if (success && mounted) {
        // Trigger initial sync
        await _healthService.syncData();
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission request failed: $e'), backgroundColor: FemLyraColors.period),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FemLyraColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, size: 60, color: FemLyraColors.primary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Unlock Smarter Insights',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'By connecting your health data via Health Connect, FemLyra can provide more accurate cycle and wellness predictions. Your data is synced securely from your device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: FemLyraColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'FemLyra reads data like steps, activity, and sleep to correlate them with your hormonal phases for better insights.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 48),
            _buildBenefitRow(Icons.auto_awesome, 'Improved Cycle Prediction', 'Syncing steps and activity helps AI detect patterns.'),
            const SizedBox(height: 24),
            _buildBenefitRow(Icons.bedtime, 'Better Sleep Analysis', 'Correlate sleep quality with your hormonal phases.'),
            const SizedBox(height: 24),
            _buildBenefitRow(Icons.lock, 'Medical-Grade Privacy', 'Your health data is encrypted and never sold.'),
            const SizedBox(height: 60),
            PrimaryButton(
              label: _isRequesting ? 'Connecting...' : 'Allow Connection',
              isLoading: _isRequesting,
              onPressed: _isRequesting ? null : _handleConnect,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now', style: TextStyle(color: FemLyraColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: FemLyraColors.primary, size: 20),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: FemLyraColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
