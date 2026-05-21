import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycles/data/cycle_service.dart';
import '../settings/data/settings_service.dart';
import 'data/profile_service.dart';
import '../auth/login_screen.dart';

class CyclePeriodSettingsScreen extends StatefulWidget {
  const CyclePeriodSettingsScreen({super.key});

  @override
  State<CyclePeriodSettingsScreen> createState() => _CyclePeriodSettingsScreenState();
}

class _CyclePeriodSettingsScreenState extends State<CyclePeriodSettingsScreen> {
  final CycleService _cycleService = CycleService();
  final SettingsService _settingsService = SettingsService();
  final ProfileService _profileService = ProfileService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _dashboardData;
  UserSettings? _settings;
  UserProfile? _profile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _cycleService.getDashboard();
      final settingsData = await _settingsService.getSettings();
      final profile = await _profileService.getProfile();
      
      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _settings = UserSettings.fromJson(settingsData);
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _handleUnauthorized();
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load data.';
      });
    }
  }

  void _handleUnauthorized() {
    // Clear tokens and navigate to login
    // Assuming ApiClient or AuthService handles token clearing, 
    // but here we force navigation as per requirement.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login again')),
    );
  }

  Future<void> _saveSettings() async {
    if (_settings == null || _profile == null) return;

    setState(() => _isSaving = true);

    try {
      await _settingsService.updateSettings({
        'fertility_predictions': _settings!.fertilityPredictions,
        'pms_reminders': _settings!.pmsReminders,
        'period_reminders': _settings!.periodReminders,
      });
      
      await _profileService.updateProfile({'goal': _profile!.goal});
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle settings updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _handleUnauthorized();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: ${e.toString().replaceAll('ApiException: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectLastPeriodDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dashboardData?['last_period_start_date'] != null 
          ? DateTime.parse(_dashboardData!['last_period_start_date']) 
          : DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: FemFlowColors.primary,
              onPrimary: Colors.white,
              onSurface: FemFlowColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _isSaving = true);
      try {
        await _cycleService.startPeriod(periodStartDate: picked);
        await _fetchData();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Last period date updated')),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update date: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Not logged yet';
    try {
      final date = dateVal is String ? DateTime.parse(dateVal) : dateVal;
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return 'Not logged yet';
    }
  }

  String _getGoalLabel(String? goal) {
    switch (goal) {
      case 'track_cycle': return 'Track my cycle';
      case 'conceive': return 'Trying to conceive';
      case 'avoid_pregnancy': return 'Avoid pregnancy';
      default: return 'Track my cycle';
    }
  }

  void _showGoalBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Tracking Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildGoalOption('track_cycle', 'Track my cycle'),
            _buildGoalOption('conceive', 'Trying to conceive'),
            _buildGoalOption('avoid_pregnancy', 'Avoid pregnancy'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String value, String label) {
    return ListTile(
      title: Text(label),
      trailing: _profile?.goal == value ? const Icon(Icons.check, color: FemFlowColors.primary) : null,
      onTap: () {
        setState(() {
          _profile = UserProfile(
            username: _profile!.username,
            email: _profile!.email,
            fullName: _profile!.fullName,
            age: _profile!.age,
            goal: value,
            isProfileComplete: _profile!.isProfileComplete,
          );
        });
        Navigator.pop(context);
      },
    );
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
          'Cycle & Period Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: FemFlowColors.period)),
                          TextButton(onPressed: _fetchData, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingRow(
                          'Average Cycle Length', 
                          _dashboardData?['average_cycle_length'] != null 
                              ? '${_dashboardData!['average_cycle_length']} days' 
                              : 'Not enough data yet',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Average cycle length is calculated from your logs.')),
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                        _buildSettingRow(
                          'Last Period Start Date', 
                          _formatDate(_dashboardData?['last_period_start_date']),
                          onTap: _selectLastPeriodDate,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                        _buildSettingRow(
                          'Tracking Goal', 
                          _getGoalLabel(_profile?.goal),
                          onTap: _showGoalBottomSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildToggleRow(
                          label: 'Fertility predictions',
                          value: _settings?.fertilityPredictions ?? true,
                          onChanged: (val) => setState(() {
                            _settings = UserSettings(
                              appearance: _settings!.appearance,
                              language: _settings!.language,
                              weightUnit: _settings!.weightUnit,
                              heightUnit: _settings!.heightUnit,
                              temperatureUnit: _settings!.temperatureUnit,
                              fertilityPredictions: val,
                              pmsReminders: _settings!.pmsReminders,
                              periodReminders: _settings!.periodReminders,
                            );
                          }),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                        _buildToggleRow(
                          label: 'PMS reminders',
                          value: _settings?.pmsReminders ?? true,
                          onChanged: (val) => setState(() {
                            _settings = UserSettings(
                              appearance: _settings!.appearance,
                              language: _settings!.language,
                              weightUnit: _settings!.weightUnit,
                              heightUnit: _settings!.heightUnit,
                              temperatureUnit: _settings!.temperatureUnit,
                              fertilityPredictions: _settings!.fertilityPredictions,
                              pmsReminders: val,
                              periodReminders: _settings!.periodReminders,
                            );
                          }),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                        _buildToggleRow(
                          label: 'Period reminders',
                          value: _settings?.periodReminders ?? true,
                          onChanged: (val) => setState(() {
                            _settings = UserSettings(
                              appearance: _settings!.appearance,
                              language: _settings!.language,
                              weightUnit: _settings!.weightUnit,
                              heightUnit: _settings!.heightUnit,
                              temperatureUnit: _settings!.temperatureUnit,
                              fertilityPredictions: _settings!.fertilityPredictions,
                              pmsReminders: _settings!.pmsReminders,
                              periodReminders: val,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: 'Done',
                    isLoading: _isSaving,
                    onPressed: _saveSettings,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, color: FemFlowColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: FemFlowColors.textPrimary),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: FemFlowColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: FemFlowColors.border,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
