import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/referral_models.dart';

class ReferralStatsCard extends StatelessWidget {
  final ReferralProfile profile;

  const ReferralStatsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                'Successful',
                profile.successfulReferrals.toString(),
                Icons.people_outline,
                Colors.blue,
              ),
              Container(height: 40, width: 1, color: FemFlowColors.border),
              _buildStatItem(
                'Months Earned',
                profile.rewardMonthsEarned.toString(),
                Icons.star_outline,
                Colors.orange,
              ),
            ],
          ),
          if (profile.premiumUntil != null) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Premium valid until ${DateFormat('MMM d, yyyy').format(profile.premiumUntil!)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: FemFlowColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
