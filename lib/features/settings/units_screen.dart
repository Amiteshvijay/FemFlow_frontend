import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/settings_service.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final SettingsService _settingsService = SettingsService();
  
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _temperatureUnit = 'celsius';
  
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
        _weightUnit = data['weight_unit'] ?? 'kg';
        _heightUnit = data['height_unit'] ?? 'cm';
        _temperatureUnit = data['temperature_unit'] ?? 'celsius';
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

  Future<void> _updateUnit(String key, String value) async {
    final oldWeight = _weightUnit;
    final oldHeight = _heightUnit;
    final oldTemp = _temperatureUnit;

    setState(() {
      if (key == 'weight_unit') _weightUnit = value;
      if (key == 'height_unit') _heightUnit = value;
      if (key == 'temperature_unit') _temperatureUnit = value;
      _isSaving = true;
    });

    try {
      await _settingsService.updateSettings({key: value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units updated'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weightUnit = oldWeight;
        _heightUnit = oldHeight;
        _temperatureUnit = oldTemp;
      });
      
      String message = 'Failed to update setting';
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
        title: const Text('Units', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildOptionRow('weight_unit', 'kg', 'Kilograms (kg)', _weightUnit == 'kg'),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                            _buildOptionRow('weight_unit', 'lb', 'Pounds (lb)', _weightUnit == 'lb'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Height', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildOptionRow('height_unit', 'cm', 'Centimeters (cm)', _heightUnit == 'cm'),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                            _buildOptionRow('height_unit', 'ft', 'Feet (ft)', _heightUnit == 'ft'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Temperature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildOptionRow('temperature_unit', 'celsius', 'Celsius (°C)', _temperatureUnit == 'celsius'),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: FemFlowColors.border),
                            _buildOptionRow('temperature_unit', 'fahrenheit', 'Fahrenheit (°F)', _temperatureUnit == 'fahrenheit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOptionRow(String key, String value, String label, bool isSelected) {
    return InkWell(
      onTap: () => _updateUnit(key, value),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: FemFlowColors.textPrimary)),
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
