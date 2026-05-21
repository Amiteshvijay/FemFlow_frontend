import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'cloud_sync_service.dart';
import 'backup_encryption_service.dart';
import 'widgets/sync_status_card.dart';
import 'widgets/sync_action_card.dart';
import '../subscriptions/providers/subscription_provider.dart';
import '../premium/premium_feature_preview_screen.dart';

class SecureCloudSyncScreen extends StatefulWidget {
  const SecureCloudSyncScreen({super.key});

  @override
  State<SecureCloudSyncScreen> createState() => _SecureCloudSyncScreenState();
}

class _SecureCloudSyncScreenState extends State<SecureCloudSyncScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CloudSyncService>().fetchStatus();
    });
  }

  String _cleanErrorMessage(dynamic error) {
    var errStr = error.toString();
    
    // Strip prefixes first
    if (errStr.startsWith('CloudSyncException:')) {
      errStr = errStr.replaceFirst('CloudSyncException:', '').trim();
    } else if (errStr.startsWith('Exception:')) {
      errStr = errStr.replaceFirst('Exception:', '').trim();
    }
    
    // If it is a developer/OAuth setup error
    if (errStr.contains('ApiException: 10') || errStr.contains('sign_in_failed')) {
      return 'Google Drive connection failed.\nPlease check your Google Sign-In / OAuth configuration (SHA-1/package name) or try again.';
    }
    
    return errStr;
  }

  void _showErrorSnackBar(dynamic error) {
    if (!mounted) return;
    final message = _cleanErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: FemFlowColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleToggle(bool value) async {
    final syncService = context.read<CloudSyncService>();
    if (value) {
      _showEnableDialog(syncService);
    } else {
      _showDisableDialog(syncService);
    }
  }

  Future<void> _handleBackupNow(CloudSyncService syncService, bool isEnabled) async {
    try {
      if (!isEnabled) {
        // If not connected/enabled, connect account and enable first
        if (syncService.status?.googleAccountEmail == null) {
          await syncService.connectAccount();
        }
        await syncService.enableSync();
      } else {
        await syncService.performBackup();
      }
      _showSuccessSnackBar('Backup uploaded successfully to Google Drive!');
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  void _showEnableDialog(CloudSyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enable Secure Cloud Sync?'),
        content: const Text(
          'FemFlow will create an encrypted backup of your data in your Google Drive. Only FemFlow can read this backup after you restore it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              try {
                if (syncService.status?.googleAccountEmail == null) {
                  await syncService.connectAccount();
                }
                await syncService.enableSync();
                if (mounted) _showRecoveryKeyDialog();
              } catch (e) {
                _showErrorSnackBar(e);
              }
            },
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog(CloudSyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Turn off Secure Cloud Sync?'),
        content: const Text(
          'FemFlow will stop syncing new backups. Existing backup files in your Google Drive will remain unless you delete them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await syncService.disableSync(deleteRemote: false);
                _showSuccessSnackBar('Secure Cloud Sync disabled.');
              } catch (e) {
                _showErrorSnackBar(e);
              }
            },
            child: const Text('Turn Off', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await syncService.disableSync(deleteRemote: true);
                _showSuccessSnackBar('Secure Cloud Sync disabled and backup deleted.');
              } catch (e) {
                _showErrorSnackBar(e);
              }
            },
            child: const Text('Turn Off & Delete Backup', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecoveryKeyDialog() async {
    final key = await BackupEncryptionService().exportRecoveryKey();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: FemFlowColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Backup Recovery Key',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save this recovery key in a safe place. You will need it to restore your data on a new device.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FemFlowColors.warmWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FemFlowColors.border),
              ),
              child: SelectableText(
                key,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recovery key copied!')));
            },
            child: const Text('Copy Key'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Secure Cloud Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Consumer<CloudSyncService>(
        builder: (context, syncService, _) {
          final status = syncService.status;
          final isEnabled = status?.enabled ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last Backup',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SyncStatusCard(status: status),
                const SizedBox(height: 32),
                
                _buildSectionTitle('Google Drive Settings'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle_outlined, color: FemFlowColors.textSecondary),
                        title: const Text('Google Account', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(status?.googleAccountEmail ?? 'Not connected', style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                           try {
                             await syncService.connectAccount();
                             _showSuccessSnackBar('Google account connected successfully.');
                           } catch (e) {
                             _showErrorSnackBar(e);
                           }
                        },
                        trailing: status?.googleAccountEmail != null 
                          ? TextButton(
                              onPressed: () => syncService.disconnectAccount(),
                              child: const Text('Change', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
                            )
                          : const Icon(Icons.chevron_right, size: 20),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildToggleItem(
                        title: 'Back up to Google Drive',
                        subtitle: 'Keep your data safe and synced',
                        value: isEnabled,
                        isLoading: syncService.isSyncing,
                        onChanged: syncService.isSyncing ? (_) {} : _handleToggle,
                      ),
                      if (isEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        _buildToggleItem(
                          title: 'Auto Daily Sync',
                          subtitle: 'Automatically sync every 24h',
                          value: status?.autoSyncEnabled ?? true,
                          onChanged: (val) async {
                            final provider = context.read<SubscriptionProvider>();
                            final navigator = Navigator.of(context);
                            
                            final isPremium = provider.isPremium;
                            if (!isPremium && val) {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'auto_sync'),
                                ),
                              );
                              return;
                            }

                            try {
                              await syncService.updateAutoSync(val);
                              _showSuccessSnackBar('Auto Daily Sync preference updated.');
                            } catch (e) {
                              _showErrorSnackBar(e);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildSectionTitle('Actions'),
                SyncActionCard(
                  icon: Icons.sync,
                  title: 'Back Up Now',
                  subtitle: 'Immediate manual backup',
                  isLoading: syncService.isSyncing,
                  onTap: syncService.isSyncing ? null : () => _handleBackupNow(syncService, isEnabled),
                ),
                if (isEnabled) ...[
                  const SizedBox(height: 16),
                  SyncActionCard(
                    icon: Icons.settings_backup_restore,
                    title: 'Restore Backup',
                    subtitle: 'Merge Cloud data to this device',
                    onTap: () => _showRestoreConfirm(syncService),
                  ),
                  const SizedBox(height: 16),
                  SyncActionCard(
                    icon: Icons.vpn_key_outlined,
                    title: 'View Recovery Key',
                    subtitle: 'Your private encryption key',
                    onTap: _showRecoveryKeyDialog,
                  ),
                ],

                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.security_outlined, color: FemFlowColors.textMuted, size: 32),
                      SizedBox(height: 12),
                      Text(
                        'Your backup is end-to-end encrypted.\nOnly you can access your health data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRestoreConfirm(CloudSyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Cloud?'),
        content: const Text(
          'This will merge your Cloud backup with your current device data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              try {
                await syncService.restoreBackup();
                _showSuccessSnackBar('Restore completed successfully!');
              } catch (e) {
                _showErrorSnackBar(e);
              }
            },
            child: const Text('Restore Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLoading = false,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isLoading 
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: FemFlowColors.primary)
                ),
                SizedBox(height: 4),
                Text('Syncing...', style: TextStyle(fontSize: 8, color: FemFlowColors.primary)),
              ],
            )
          : Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: FemFlowColors.primary,
              activeTrackColor: FemFlowColors.primary.withValues(alpha: 0.3),
            ),
    );
  }
}
