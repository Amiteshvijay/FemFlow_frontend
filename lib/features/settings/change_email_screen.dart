import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../profile/data/profile_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  final String currentEmail;
  const ChangeEmailScreen({super.key, required this.currentEmail});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final ProfileService _profileService = ProfileService();
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  bool _showForm = false;
  String? _error;
  int _countdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Please enter a valid email address.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _profileService.sendEmailChangeOtp(email);
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('ApiException: ', '');
      });
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      setState(() => _error = "Please enter the 6-digit verification code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _profileService.verifyEmailChangeOtp(
        email: email,
        otp: otp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email address changed successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('ApiException: ', '');
        for (var c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      });
    }
  }

  void _checkAutoVerify() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _verifyOtp();
    }
  }

  Widget _buildCurrentEmailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your registered email address is:',
          style: TextStyle(color: FemFlowColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FemFlowColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: FemFlowColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Email Address',
                      style: TextStyle(
                        color: FemFlowColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.currentEmail.isNotEmpty ? widget.currentEmail : 'Not Set',
                      style: const TextStyle(
                        color: FemFlowColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Change Email Address',
          onPressed: () {
            setState(() {
              _showForm = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildChangeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update your registered email address below. A verification code will be sent to the new email.',
          style: TextStyle(color: FemFlowColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          enabled: !_otpSent && !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 32),
          const Text(
            'Enter the 6-digit verification code sent to your new email address:',
            style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 42,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  enabled: !_isLoading,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                  decoration: InputDecoration(
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: FemFlowColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: FemFlowColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    if (_error != null) {
                      setState(() => _error = null);
                    }
                    if (value.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    _checkAutoVerify();
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _countdown == 0 && !_isLoading ? _sendOtp : null,
                child: Text(
                  _countdown == 0 ? 'Resend Verification Code' : 'Resend Code in ${_countdown}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: _countdown == 0 ? FemFlowColors.primary : FemFlowColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: FemFlowColors.period, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 40),
        PrimaryButton(
          label: _otpSent ? 'Verify & Update' : 'Send Verification Code',
          isLoading: _isLoading,
          onPressed: _otpSent ? _verifyOtp : _sendOtp,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_showForm) {
              setState(() {
                _showForm = false;
                _otpSent = false;
                _emailController.clear();
                for (var c in _otpControllers) {
                  c.clear();
                }
                _error = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Email Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _showForm ? _buildChangeForm() : _buildCurrentEmailView(),
      ),
    );
  }
}
