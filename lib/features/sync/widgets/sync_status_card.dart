import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/cloud_sync_models.dart';

class SyncStatusCard extends StatelessWidget {
  final CloudSyncStatus? status;

  const SyncStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const AppCard(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isEnabled = status!.enabled;
    
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isEnabled ? FemFlowColors.primary : FemFlowColors.textMuted).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: isEnabled ? FemFlowColors.primary : FemFlowColors.textMuted,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnabled ? 'Sync Enabled' : 'Sync Disabled',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                    ),
                    if (isEnabled && status!.googleAccountEmail != null)
                      Text(
                        status!.googleAccountEmail!,
                        style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(height: 32),
            _buildInfoRow('Last Backup', status!.lastSyncAt != null ? _formatDate(status!.lastSyncAt!) : 'Never'),
            const SizedBox(height: 12),
            _buildInfoRow('Backup Size', status!.lastBackupSize != null ? _formatSize(status!.lastBackupSize!) : 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow('Last Restore', status!.lastRestoreAt != null ? _formatDate(status!.lastRestoreAt!) : 'Never'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemFlowColors.textPrimary)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
