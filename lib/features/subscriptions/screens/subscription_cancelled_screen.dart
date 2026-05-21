import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/subscription_provider.dart';

class SubscriptionCancelledScreen extends StatelessWidget {
  const SubscriptionCancelledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        final endDate = provider.status?.subscriptionEndDate ?? DateTime.now().add(const Duration(days: 30));
        final formattedDate = DateFormat('d MMMM yyyy').format(endDate);
        
        return Scaffold(
          backgroundColor: FemFlowColors.warmWhite,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Subscription Cancelled',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your auto-renewal has been turned off. Your FemFlow Premium benefits will remain active until your billing period ends on $formattedDate.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: FemFlowColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  AppCard(
                    color: FemFlowColors.primary.withValues(alpha: 0.05),
                    child: Column(
                      children: [
                        const Text(
                          'Wait, I changed my mind!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can keep your Premium benefits active and continue your wellness journey without interruption.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Keep Premium',
                          onPressed: () {
                             // In a real app, this would call a "reactivate" API
                             // For MVP, we navigate back to status
                             Navigator.popUntil(context, (route) => route.isFirst);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Back to Profile', style: TextStyle(color: FemFlowColors.textMuted, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
