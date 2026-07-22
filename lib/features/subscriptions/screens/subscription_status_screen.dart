import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/subscription_provider.dart';
import './billing_history_screen.dart';
import './premium_plan_screen.dart';
import './subscription_retention_screen.dart';

class SubscriptionStatusScreen extends StatelessWidget {
  const SubscriptionStatusScreen({super.key});

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
        title: const Text('My Subscription', style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          final status = provider.status;
          if (status == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(status),
                const SizedBox(height: 32),
                if (status.hasPremiumAccess) ...[
                  _buildDetails(status),
                  const SizedBox(height: 32),
                ],
                _buildPremiumBenefits(),
                const SizedBox(height: 40),
                if (!status.hasPremiumAccess)
                  _buildUpgradeButton(context)
                else
                  _buildManageOptions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(dynamic status) {
    bool isPremium = status.hasPremiumAccess;
    String statusTitle = isPremium ? 'Premium Active' : 'Free Member';
    if (status.status == 'trial_active') statusTitle = 'Trial Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isPremium 
          ? const LinearGradient(
              colors: [FemFlowColors.primary, Color(0xFFFF8C94)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? FemFlowColors.primary : Colors.grey).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), 
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(isPremium ? Icons.star_rounded : Icons.person_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium ? (status.planName ?? 'Premium Plan') : 'Upgrade for full access',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(dynamic status) {
    final expiryDate = status.status == 'trial_active' ? status.trialEndDate : status.subscriptionEndDate;
    if (expiryDate == null) return const SizedBox.shrink();

    final dateStr = DateFormat('MMMM d, yyyy').format(expiryDate);
    final daysLeft = status.status == 'trial_active' ? status.trialDaysLeft : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Plan Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FemFlowColors.textPrimary)),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _detailItem('Current Status', status.status.toUpperCase().replaceAll('_', ' ')),
              const Divider(height: 32),
              _detailItem('Next billing date', dateStr),
              if (status.status == 'trial_active') ...[
                const Divider(height: 32),
                _detailItem('Trial days remaining', '$daysLeft days'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Premium Benefits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FemFlowColors.textPrimary)),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _benefitItem(Icons.psychology_outlined, 'FemAI personalized health guidance'),
              _benefitItem(Icons.analytics_outlined, 'Advanced cycle analytics'),
              _benefitItem(Icons.insights_outlined, 'Symptom and mood trends'),
              _benefitItem(Icons.fitness_center_outlined, 'Phase-synced exercise plans'),
              _benefitItem(Icons.cloud_upload_outlined, 'Unlimited Health Vault storage'),
              _benefitItem(Icons.picture_as_pdf_outlined, 'Export health reports (PDF)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _benefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: FemFlowColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FemFlowColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: FemFlowColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumPlanScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: FemFlowColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('View Premium Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildManageOptions(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillingHistoryScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.history, color: FemFlowColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                const Text('Billing History', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 20, color: FemFlowColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _showCancelDialog(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
              ),
            ),
            child: const Text(
              'Cancel Subscription',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionRetentionScreen()),
    );
  }
}
