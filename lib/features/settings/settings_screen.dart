import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'change_password_screen.dart';
import '../pill_reminder/pill_reminder_list_screen.dart';
import 'data/settings_service.dart';
import '../auth/data/auth_service.dart';
import '../auth/login_screen.dart';
import '../premium/premium_guard.dart';
import '../profile/data/profile_service.dart';
import '../profile/personal_info_screen.dart';
import '../profile/data_export_screen.dart';
import '../connected_health/screens/connected_health_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  UserSettings? _settings;
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final settingsData = await _settingsService.getSettings();
      final profileData = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _settings = UserSettings.fromJson(settingsData);
          _profile = profileData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  _buildSectionTitle('My Cycle', icon: Icons.loop),
                  _buildSettingsGroup([
                    _buildSettingsRow('Period Prediction', isToggle: true, toggleValue: _settings?.periodReminders ?? true, onToggleChanged: (val) {}),
                    _buildSettingsRow('Ovulation & Fertility', isToggle: true, toggleValue: _settings?.fertilityPredictions ?? true, onToggleChanged: (val) {}),
                  ]),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Reminders', icon: Icons.notifications_none),
                  _buildSettingsGroup([
                    _buildSettingsRow('Cycle Reminder', isToggle: true, toggleValue: true, onToggleChanged: (val) {}),
                    _buildSettingsRow('Medication Reminder', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PillReminderListScreen()));
                    }),
                    _buildSettingsRow('Daily Logging Reminder', isToggle: true, toggleValue: true, onToggleChanged: (val) {}),
                  ]),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Personal & Privacy', icon: Icons.security),
                  _buildSettingsGroup([
                    _buildSettingsRow(
                      'Name', 
                      value: _profile?.fullName ?? 'User', 
                      showChevron: true,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PersonalInfoScreen(profile: _profile)),
                        );
                        if (result == true) _fetchSettings();
                      },
                    ),
                    _buildSettingsRow(
                      'Mobile Number', 
                      value: _profile?.mobileNumber ?? 'Not Set', 
                      showChevron: true,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PersonalInfoScreen(profile: _profile)),
                        );
                        if (result == true) _fetchSettings();
                      },
                    ),
                    _buildSettingsRow('Change Password', onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                    }),
                    _buildSettingsRow(
                      'Connected Health', 
                      subtitle: 'Android Health Connect, Google Fit, Apple Health',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectedHealthScreen()));
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Data', icon: Icons.data_usage),
                  _buildSettingsGroup([
                    _buildSettingsRow(
                      'Export My Health Report', 
                      subtitle: 'Professional PDF for your doctor',
                      onTap: () => PremiumGuard.openPremiumFeature(
                        context: context, 
                        featureKey: 'export_data', 
                        premiumScreen: const DataExportScreen()
                      ),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleLogout,
                      child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: FemFlowColors.textSecondary), const SizedBox(width: 8)],
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary, letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsRow(
    String label, {
    String? value,
    String? subtitle,
    VoidCallback? onTap,
    bool isToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    bool showChevron = true,
    Color? textColor,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: isToggle ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: FemFlowColors.border.withValues(alpha: 0.5), width: 0.5)),
          color: isSelected ? FemFlowColors.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 16, color: textColor ?? (isSelected ? FemFlowColors.primary : FemFlowColors.textPrimary), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: FemFlowColors.textMuted),
              ),
            if (isToggle)
              Switch(
                value: toggleValue,
                onChanged: onToggleChanged,
                activeThumbColor: FemFlowColors.primary,
                activeTrackColor: FemFlowColors.primary.withValues(alpha: 0.3),
              )
            else if (showChevron && !isToggle)
              const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
            if (isSelected)
              const Icon(Icons.check, color: FemFlowColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
