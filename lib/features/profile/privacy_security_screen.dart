import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../core/security/app_lock_service.dart';
import '../auth/data/auth_service.dart';
import '../app_lock/screens/create_pin_screen.dart';
import '../app_lock/screens/forgot_pin_otp_screen.dart';
import 'delete_account_verify_screen.dart';
import 'data_export_screen.dart';
import 'data/profile_service.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConsent(String field, bool value) async {
    if (_profile == null) return;
    
    // Optimistic update
    setState(() {
      _fetchProfile(); // Refresh after update
    });

    try {
      await _profileService.updateProfile({field: value});
      await _fetchProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preference: $e')),
        );
      }
    }
  }

  Future<void> _toggle2FA(bool enable) async {
    if (enable) {
      _showEnable2FADialog();
    } else {
      _showDisable2FADialog();
    }
  }

  void _showEnable2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Two-Factor Authentication?'),
        content: const Text('Each time you log in, FemLyra will send a verification code to your email.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _authService.enable2fa();
                await _fetchProfile();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Two-Factor Authentication enabled')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('ApiException: ', ''))),
                );
              }
            },
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDisable2FADialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Two-Factor Authentication?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current password to disable 2FA.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final pass = passwordController.text;
              if (pass.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _authService.disable2fa(pass);
                await _fetchProfile();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Two-Factor Authentication disabled')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('ApiException: ', ''))),
                );
              }
            },
            child: const Text('Disable', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('App Access'),
                  _buildAppLockSection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Data & Privacy'),
                  _buildDataPrivacySection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Privacy & AI Consent'),
                  _buildPrivacyAIConsentSection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Account Management'),
                  _buildAccountActionsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildAppLockSection() {
    final appLock = context.watch<AppLockService>();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildToggleItem(
            icon: Icons.lock_outline,
            title: 'App Lock',
            subtitle: 'Require PIN to open',
            value: appLock.isEnabled,
            onChanged: (val) async {
              if (val) {
                final success = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePinScreen()),
                );
                if (success == true) {
                  await appLock.setAppLockEnabled(true);
                }
              } else {
                if (appLock.isEnabled) {
                  final success = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Disable'),
                      content: const Text('Anyone with access to your device will be able to view your health logs.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Disable', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (success == true) {
                    await appLock.setAppLockEnabled(false);
                  }
                }
              }
            },
          ),
          if (appLock.isEnabled) ...[
            const Divider(height: 1, indent: 56),
            _buildClickableItem(
              icon: Icons.timer_outlined,
              title: 'Auto-lock Timeout',
              subtitle: _getTimeoutLabel(appLock.autoLockTimeout),
              onTap: _showTimeoutPicker,
            ),
            const Divider(height: 1, indent: 56),
            _buildClickableItem(
              icon: Icons.password_outlined,
              title: 'Change PIN',
              subtitle: 'Update your security PIN',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePinScreen()),
              ),
            ),
            const Divider(height: 1, indent: 56),
            _buildClickableItem(
              icon: Icons.help_outline,
              title: 'Forgot PIN?',
              subtitle: 'Reset via email verification',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPinOtpScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeoutLabel(int seconds) {
    if (seconds == 0) return 'Immediately';
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minute${seconds >= 120 ? 's' : ''}';
  }

  void _showTimeoutPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Consumer<AppLockService>(
        builder: (context, appLock, _) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Auto-lock Timeout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTimeoutOption(appLock, 0, 'Immediately'),
              _buildTimeoutOption(appLock, 30, '30 seconds'),
              _buildTimeoutOption(appLock, 60, '1 minute'),
              _buildTimeoutOption(appLock, 300, '5 minutes'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeoutOption(AppLockService appLock, int seconds, String label) {
    return ListTile(
      title: Text(label),
      trailing: appLock.autoLockTimeout == seconds ? const Icon(Icons.check, color: FemLyraColors.primary) : null,
      onTap: () {
        appLock.setAutoLockTimeout(seconds);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDataPrivacySection() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [

          _buildClickableItem(
            icon: Icons.download_for_offline_outlined,
            title: 'Export My Health Report',
            subtitle: 'Professional PDF for your doctor',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataExportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyAIConsentSection() {
    return Column(
      children: [
        AppCard(
          color: FemLyraColors.blushMist,
          child: Column(
            children: [
              const Icon(Icons.security, color: FemLyraColors.primary, size: 40),
              const SizedBox(height: 16),
              const Text('Clinical-Grade Privacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'We use your health data ONLY to provide personalized insights and predictions. Your data is never sold or used for public AI training.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildToggleItem(
                icon: Icons.analytics_outlined,
                title: 'Allow anonymous wellness insights',
                subtitle: 'Improve accuracy with pooled data',
                value: _profile?.anonymousWellnessInsights ?? true,
                onChanged: (val) => _updateConsent('anonymous_wellness_insights', val),
              ),
              const Divider(height: 1, indent: 56),
              _buildToggleItem(
                icon: Icons.auto_awesome_outlined,
                title: 'Allow personalized AI recommendations',
                subtitle: 'Get advice based on your logs',
                value: _profile?.aiRecommendationsConsent ?? true,
                onChanged: (val) => _updateConsent('ai_recommendations_consent', val),
              ),
              const Divider(height: 1, indent: 56),
              _buildToggleItem(
                icon: Icons.track_changes_outlined,
                title: 'Allow symptom-based prediction',
                subtitle: 'Refine future period estimates',
                value: _profile?.symptomPredictionConsent ?? true,
                onChanged: (val) => _updateConsent('symptom_prediction_consent', val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildToggleItem(
            icon: Icons.verified_user_outlined,
            title: 'Two-Factor Authentication',
            subtitle: _profile?.twoFactorEnabled == true 
                ? 'Secure your login with a secondary email code' 
                : 'Add an email code after password login',
            value: _profile?.twoFactorEnabled ?? false,
            onChanged: (val) => _toggle2FA(val),
          ),
          const Divider(height: 1, indent: 56),
          _buildClickableItem(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently remove all data (cannot be undone)',
            titleColor: Colors.red,
            onTap: () {
              _authService.me().then((data) {
                final email = data['email'];
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DeleteAccountVerifyScreen(email: email)),
                            );
                          }, 
                          child: const Text('Delete', style: TextStyle(color: Colors.red))
                        ),
                      ],
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: FemLyraColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: FemLyraColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: FemLyraColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: FemLyraColors.border,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: FemLyraColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor ?? FemLyraColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FemLyraColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
