import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/password_guidelines.dart';
import '../auth/login_screen.dart';
import 'data/settings_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _settingsService = SettingsService();
  
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showGuidelines = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onPasswordChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    if (newPass.length < 8 || newPass.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be between 8 and 20 characters long')),
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must contain at least one capital letter')),
      );
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must contain at least one small letter')),
      );
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must contain at least one number')),
      );
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must contain at least one special character')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _settingsService.changePassword(
        currentPassword: current,
        newPassword: newPass,
        confirmPassword: confirm,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _handleUnauthorized();
        return;
      }
      String message = 'Failed to change password';
      if (e.toString().contains('ApiException')) {
        message = e.toString().replaceAll('ApiException: ', '').split(' (Status:').first;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleUnauthorized() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login again')),
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
        title: const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              obscureText: _obscureCurrent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.help_outline_rounded,
                        color: _showGuidelines ? FemFlowColors.primary : Colors.grey,
                      ),
                      onPressed: () => setState(() => _showGuidelines = !_showGuidelines),
                    ),
                    IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ],
                ),
              ),
              obscureText: _obscureNew,
            ),
            if (_showGuidelines) ...[
              const SizedBox(height: 8),
              PasswordGuidelines(password: _newPasswordController.text),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Update Password',
              isLoading: _isLoading,
              onPressed: _handleChangePassword,
            ),
          ],
        ),
      ),
    );
  }
}
