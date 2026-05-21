import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';

class MaintenanceScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const MaintenanceScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Calming Illustration (Using Icon as placeholder)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 80,
                  color: FemFlowColors.primary,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'System Update in Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: FemFlowColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hi! FemFlow is temporarily offline for scheduled system updates. We’re working hard to get back online and expect to be live very soon. We apologize for any inconvenience caused.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: FemFlowColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                label: 'Check Again',
                onPressed: onRetry ?? () {},
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank you for your patience.',
                style: TextStyle(
                  fontSize: 12,
                  color: FemFlowColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
