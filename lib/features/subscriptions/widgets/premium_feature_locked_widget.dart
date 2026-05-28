import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../screens/premium_plan_screen.dart';

class PremiumFeatureLockedWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PremiumFeatureLockedWidget({
    super.key,
    this.title = 'Premium Feature',
    this.description = 'Unlock deeper AI insights with FemFlow Premium.',
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FemFlowColors.blushMist.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FemFlowColors.blushMist, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: FemFlowColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumPlanScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FemFlowColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
