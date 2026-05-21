import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/settings_service.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final SettingsService _settingsService = SettingsService();
  
  String _selectedAppearance = 'light';
  bool _isLoading = true;
  // ignore: unused_field
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _settingsService.getSettings();
      if (!mounted) return;
      setState(() {
        _selectedAppearance = data['appearance'] ?? 'light';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.toString().contains('503') || e.toString().contains('SocketException')) {
          _error = 'Could not connect to server. Check backend and adb reverse.';
        } else if (e.toString().contains('401')) {
          _error = 'Please login again.';
        } else {
          _error = 'Failed to load settings.';
        }
      });
    }
  }

  Future<void> _updateAppearance(String value) async {
    final previousAppearance = _selectedAppearance;
    setState(() {
      _selectedAppearance = value;
      _isSaving = true;
    });

    try {
      await _settingsService.updateSettings({'appearance': value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appearance updated'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedAppearance = previousAppearance;
      });
      
      String message = 'Failed to update appearance';
      if (e.toString().contains('503') || e.toString().contains('SocketException')) {
        message = 'Could not connect to server. Check backend and adb reverse.';
      } else if (e.toString().contains('401')) {
        message = 'Please login again.';
      } else if (e.toString().contains('ApiException')) {
        message = e.toString().replaceAll('ApiException: ', '').split(' (Status:').first;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          'Appearance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: FemFlowColors.textSecondary)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadSettings,
                          child: const Text('Retry', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildOptionRow('light', 'Light'),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                            _buildOptionRow('dark', 'Dark'),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                            _buildOptionRow('system', 'System Default'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOptionRow(String value, String label) {
    final isSelected = _selectedAppearance == value;
    return InkWell(
      onTap: () => _updateAppearance(value),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: FemFlowColors.textPrimary),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? FemFlowColors.primary : FemFlowColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
