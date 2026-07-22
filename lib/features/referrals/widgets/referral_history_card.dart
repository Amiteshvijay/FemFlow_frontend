import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/referral_models.dart';

class ReferralHistoryCard extends StatelessWidget {
  final List<ReferralHistoryItem> history;

  const ReferralHistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Text(
            'Referral History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.textPrimary,
            ),
          ),
        ),
        ...history.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _getStatusIcon(item.status),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.referredUserDisplay,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Joined ${DateFormat('MMM d, yyyy').format(item.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (item.status == 'rewarded')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${item.rewardMonths} Mo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'rewarded':
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case 'activated':
        return const Icon(Icons.hourglass_empty, color: Colors.blue, size: 24);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey, size: 24);
    }
  }
}
