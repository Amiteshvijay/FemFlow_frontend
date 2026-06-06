import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../auth/data/auth_service.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';

class DeleteAccountVerifyScreen extends StatefulWidget {
  final String email;
  const DeleteAccountVerifyScreen({super.key, required this.email});

  @override
  State<DeleteAccountVerifyScreen> createState() => _DeleteAccountVerifyScreenState();
}

class _DeleteAccountVerifyScreenState extends State<DeleteAccountVerifyScreen> {
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameConfirmationController = TextEditingController();
  final _otherReasonController = TextEditingController();
  final _authService = AuthService();

  int _currentStep = 1; // 1: Password, 2: OTP, 3: Final Confirmation
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _selectedReason;
  String? _userProfileFullName;

  final List<String> _deletionReasons = [
    'I no longer need cycle tracking',
    'I found a different app',
    'Privacy concerns',
    'Too many notifications',
    'Technical issues/bugs',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileName();
  }

  Future<void> _fetchProfileName() async {
    try {
      final data = await _authService.me();
      setState(() {
        _userProfileFullName = data['profile']['full_name'] ?? data['full_name'];
      });
    } catch (e) {
      // Fallback
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    _nameConfirmationController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _authService.verifyDeletionPassword(_passwordController.text);
      await _authService.sendDeletionOtp(widget.email);
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FemFlowColors.period),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) return;
    setState(() => _isLoading = true);
    try {
      await _authService.verifyDeletionOtp(widget.email, _otpController.text);
      setState(() {
        _currentStep = 3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP'), backgroundColor: FemFlowColors.period),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    try {
      String finalReason = _selectedReason ?? 'Other';
      if (_selectedReason == 'Other' && _otherReasonController.text.isNotEmpty) {
        finalReason = 'Other: ${_otherReasonController.text.trim()}';
      }
      
      await _authService.submitDeletionRequest(widget.email, finalReason);
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: FemFlowColors.period),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 36,
              backgroundColor: FemFlowColors.fertileWindow,
              child: Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Deactivation Scheduled',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your request has been received. Your account is now deactivated and will be permanently deleted within 7 days.\n\nYou have been logged out.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Understood',
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  final navigator = Navigator.of(context, rootNavigator: true);
                  await authProvider.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool get _isDeletionReady {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other' && _otherReasonController.text.trim().isEmpty) return false;
    if (_userProfileFullName == null) return false;
    return _nameConfirmationController.text.trim() == _userProfileFullName!.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Account Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (_currentStep == 1) _buildPasswordStep(),
            if (_currentStep == 2) _buildOtpStep(),
            if (_currentStep == 3) _buildFinalConfirmationStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = "";
    String subtitle = "";
    if (_currentStep == 1) {
      title = "Verification Required";
      subtitle = "To ensure the security of your health data, please verify your identity with your account password.";
    } else if (_currentStep == 2) {
      title = "Confirm Email Access";
      subtitle = "We have sent a secure 6-digit verification code to your registered email ${widget.email}.";
    } else {
      title = "Final Confirmation";
      subtitle = "This action is irreversible after 7 days. Your account will be immediately deactivated upon confirmation.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: FemFlowColors.textSecondary, height: 1.4, fontSize: 14)),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Continue to Email Verification',
          isLoading: _isLoading,
          onPressed: _verifyPassword,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: '6-Digit Verification Code',
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Verify and Continue',
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
        TextButton(
          onPressed: _isLoading ? null : () => _authService.sendDeletionOtp(widget.email),
          child: const Text('Didn\'t receive code? Resend'),
        ),
      ],
    );
  }

  Widget _buildFinalConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason for Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemFlowColors.textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedReason,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
          ),
          hint: const Text('Select a reason'),
          items: _deletionReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) => setState(() => _selectedReason = val),
        ),
        if (_selectedReason == 'Other') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _otherReasonController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Please tell us why you want to delete your account',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
            ),
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 14, height: 1.4),
            children: [
              const TextSpan(text: 'To confirm, please type your Full Name exactly as: '),
              TextSpan(text: _userProfileFullName ?? '...', style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameConfirmationController,
          onChanged: (_) => setState(() {}), // Refresh button state
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (_isLoading || !_isDeletionReady) ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Confirm Account Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Your account will be deactivated immediately and permanently deleted within 7 days.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
