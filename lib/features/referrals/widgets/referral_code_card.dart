import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';

class ReferralCodeCard extends StatelessWidget {
  final String code;

  const ReferralCodeCard({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: FemFlowColors.primary.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.primary.withValues(alpha: 0.2)),
      child: Column(
        children: [
          const Text(
            'Your Referral Code',
            style: TextStyle(
              fontSize: 14,
              color: FemFlowColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FemFlowColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: FemFlowColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Referral code copied!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.copy, color: FemFlowColors.primary, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
