import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/auth_service.dart';
import 'providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String email;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.email,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthService _authService = AuthService();

  final List<TextEditingController> _emailControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());

  final List<TextEditingController> _phoneControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _phoneFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _acceptTerms = false;
  String? _error;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _emailControllers) {
      c.dispose();
    }
    for (var f in _emailFocusNodes) {
      f.dispose();
    }
    for (var c in _phoneControllers) {
      c.dispose();
    }
    for (var f in _phoneFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _isButtonEnabled() {
    final emailOtp = _emailControllers.map((c) => c.text).join();
    final phoneOtp = _phoneControllers.map((c) => c.text).join();
    return emailOtp.length == 6 && phoneOtp.length == 6 && _acceptTerms && !_isLoading;
  }

  void _checkAutoVerify() {
    if (_isButtonEnabled()) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final emailOtp = _emailControllers.map((c) => c.text).join();
    final phoneOtp = _phoneControllers.map((c) => c.text).join();

    if (emailOtp.length < 6 || phoneOtp.length < 6) {
      setState(() => _error = "Please enter both 6-digit codes");
      return;
    }

    if (!_acceptTerms) {
      setState(() => _error = "You must accept the Terms and Conditions");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.verifySignupOtp(
        verificationId: widget.verificationId,
        emailOtp: emailOtp,
        phoneOtp: phoneOtp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<AuthProvider>().notifyLogin();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('ApiException: ', '');
        if (errorMsg.toLowerCase().contains('invalid otp')) {
          errorMsg = "Invalid OTP. Please enter the correct verification code.";
        }
        setState(() {
          _isLoading = false;
          _error = errorMsg;
        });
      }
    }
  }

  Future<void> _resend(String channel) async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.resendSignupOtp(
        verificationId: widget.verificationId,
        channel: channel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code resent to $channel'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTermsDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(color: FemFlowColors.textSecondary, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
            ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 60, color: FemFlowColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Verify Your Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'We have sent separate verification codes to verify your details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FemFlowColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),

              // Email OTP Group
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: 'Email Code sent to: ',
                    style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildOtpRow(
                controllers: _emailControllers,
                focusNodes: _emailFocusNodes,
                onChanged: (val) {
                  _checkAutoVerify();
                },
              ),
              const SizedBox(height: 24),

              // Phone OTP Group
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: 'SMS Code sent to: ',
                    style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(
                        text: widget.phone,
                        style: const TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildOtpRow(
                controllers: _phoneControllers,
                focusNodes: _phoneFocusNodes,
                onChanged: (val) {
                  _checkAutoVerify();
                },
              ),
              const SizedBox(height: 32),

              // Terms and Conditions checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (val) {
                      setState(() {
                        _acceptTerms = val ?? false;
                        if (_error != null) _error = null;
                      });
                      _checkAutoVerify();
                    },
                    activeColor: FemFlowColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: FemFlowColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showTermsDialog(
                                  context,
                                  'Terms of Service',
                                  'Welcome to FemFlow. By using our services, you agree to track your cycles and respect privacy-first health guidelines. All user data is encrypted and securely stored in compliance with standard protocols...',
                                );
                              },
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: FemFlowColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showTermsDialog(
                                  context,
                                  'Privacy Policy',
                                  'Your privacy is our utmost priority. FemFlow collects cycle information, mood details, and reminders to customize your wellness predictions. We never sell, share, or disclose your health data with any third parties.',
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: FemFlowColors.period, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _isButtonEnabled() ? _verify : null,
              ),

              const SizedBox(height: 24),
              Text(
                "Didn't receive codes?",
                style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _resendCountdown == 0 ? () => _resend('email') : null,
                    child: Text(
                      _resendCountdown == 0 ? 'Resend Email Code' : 'Resend Email in ${_resendCountdown}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: _resendCountdown == 0 ? FemFlowColors.primary : FemFlowColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: FemFlowColors.border)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _resendCountdown == 0 ? () => _resend('phone') : null,
                    child: Text(
                      _resendCountdown == 0 ? 'Resend SMS Code' : 'Resend SMS in ${_resendCountdown}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: _resendCountdown == 0 ? FemFlowColors.primary : FemFlowColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpRow({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required Function(String) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 42,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
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
                focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
              onChanged(controllers.map((c) => c.text).join());
            },
          ),
        );
      }),
    );
  }
}
