import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/subscription_provider.dart';
import 'subscription_cancel_otp_screen.dart';

class SubscriptionRetentionScreen extends StatelessWidget {
  const SubscriptionRetentionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.favorite_rounded, color: FemLyraColors.primary, size: 64),
                    const SizedBox(height: 24),
                    const Text(
                      'Are you sure you want to leave FemLyra Premium?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You’ll lose access to personalized wellness insights and premium health features designed for your cycle and wellbeing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: FemLyraColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    _buildBenefitItem(
                      icon: Icons.auto_awesome,
                      title: 'AI Health Insights',
                      subtitle: 'Personalized analysis of your daily health logs.',
                    ),
                    _buildBenefitItem(
                      icon: Icons.track_changes,
                      title: 'Advanced Cycle Predictions',
                      subtitle: 'Highly accurate period and ovulation forecasting.',
                    ),
                    _buildBenefitItem(
                      icon: Icons.medical_information,
                      title: 'Premium Reports',
                      subtitle: 'Comprehensive PDF reports for your doctor.',
                    ),
                    _buildBenefitItem(
                      icon: Icons.connect_without_contact,
                      title: 'Connected Health',
                      subtitle: 'Sync with Apple Health and Google Fit.',
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: FemLyraColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Keep Premium',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _initiateCancellation(context),
            child: const Text(
              'Cancel Anyway',
              style: TextStyle(color: FemLyraColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateCancellation(BuildContext context) async {
    final provider = context.read<SubscriptionProvider>();
    try {
      await provider.initiateCancellation();
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionCancelOtpScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
