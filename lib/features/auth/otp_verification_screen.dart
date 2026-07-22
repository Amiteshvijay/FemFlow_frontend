import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/auth_service.dart';

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

  bool _emailVerified = false;
  bool _phoneVerified = false;

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
    final emailReady = _emailVerified || emailOtp.length == 6;
    final phoneReady = _phoneVerified || phoneOtp.length == 6;
    return emailReady && phoneReady && _acceptTerms && !_isLoading;
  }

  Future<void> _verify() async {
    setState(() => _error = null);
    if (!_emailVerified) {
      await _verifyEmail();
    }
    if (!_phoneVerified) {
      await _verifyPhone();
    }
    if (_emailVerified && _phoneVerified) {
      if (_acceptTerms) {
        _onSignupComplete();
      } else {
        setState(() {
          _error = "Please accept the Terms of Service & Privacy Policy.";
        });
      }
    }
  }

  Future<void> _verifyEmail() async {
    final emailOtp = _emailControllers.map((c) => c.text).join();
    if (emailOtp.length < 6 || _emailVerified || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _authService.verifySignupOtp(
        verificationId: widget.verificationId,
        emailOtp: emailOtp,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res['email_verified'] == true) {
            _emailVerified = true;
            for (var c in _emailControllers) {
              c.text = '*';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email OTP verified successfully."),
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (!_phoneVerified) {
              _phoneFocusNodes[0].requestFocus();
            }
          }
        });

        if (_emailVerified && _phoneVerified && _acceptTerms) {
          _onSignupComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('ApiException: ', '');
        if (errorMsg.toLowerCase().contains('invalid otp')) {
          errorMsg = "Invalid Email OTP. Please enter the correct verification code.";
        }
        setState(() {
          _isLoading = false;
          _error = errorMsg;
          for (var c in _emailControllers) {
            c.clear();
          }
          _emailFocusNodes[0].requestFocus();
        });
      }
    }
  }

  Future<void> _verifyPhone() async {
    final phoneOtp = _phoneControllers.map((c) => c.text).join();
    if (phoneOtp.length < 6 || _phoneVerified || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _authService.verifySignupOtp(
        verificationId: widget.verificationId,
        phoneOtp: phoneOtp,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res['phone_verified'] == true) {
            _phoneVerified = true;
            for (var c in _phoneControllers) {
              c.text = '*';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Phone OTP verified successfully."),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });

        if (_emailVerified && _phoneVerified && _acceptTerms) {
          _onSignupComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('ApiException: ', '');
        if (errorMsg.toLowerCase().contains('invalid otp')) {
          errorMsg = "Invalid Phone OTP. Please enter the correct verification code.";
        }
        setState(() {
          _isLoading = false;
          _error = errorMsg;
          for (var c in _phoneControllers) {
            c.clear();
          }
          _phoneFocusNodes[0].requestFocus();
        });
      }
    }
  }

  Future<void> _onSignupComplete() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully! Please login to continue."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _authService.logout();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _checkAutoVerify() {
    final emailOtp = _emailControllers.map((c) => c.text).join();
    final phoneOtp = _phoneControllers.map((c) => c.text).join();

    if (emailOtp.length == 6 && !_emailVerified && !_isLoading) {
      _verifyEmail();
    }
    if (phoneOtp.length == 6 && !_phoneVerified && !_isLoading) {
      _verifyPhone();
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
          style: const TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(color: FemLyraColors.textSecondary, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold),
            ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 60, color: FemLyraColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Verify Your Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'We have sent separate verification codes to verify your details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FemLyraColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),

              // Email OTP Group
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Email Code sent to: ',
                        style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_emailVerified)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: FemLyraColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(color: FemLyraColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildOtpRow(
                controllers: _emailControllers,
                focusNodes: _emailFocusNodes,
                onChanged: (val) {
                  _checkAutoVerify();
                },
                isEnabled: !_emailVerified,
              ),
              const SizedBox(height: 24),

              // Phone OTP Group
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'SMS Code sent to: ',
                        style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: widget.phone,
                            style: const TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_phoneVerified)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: FemLyraColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(color: FemLyraColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildOtpRow(
                controllers: _phoneControllers,
                focusNodes: _phoneFocusNodes,
                onChanged: (val) {
                  _checkAutoVerify();
                },
                isEnabled: !_phoneVerified,
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
                    activeColor: FemLyraColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: FemLyraColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showTermsDialog(
                                  context,
                                  'Terms of Service',
                                  'Welcome to FemLyra. By using our services, you agree to track your cycles and respect privacy-first health guidelines. All user data is encrypted and securely stored in compliance with standard protocols...',
                                );
                              },
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: FemLyraColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showTermsDialog(
                                  context,
                                  'Privacy Policy',
                                  'Your privacy is our utmost priority. FemLyra collects cycle information, mood details, and reminders to customize your wellness predictions. We never sell, share, or disclose your health data with any third parties.',
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
                    style: const TextStyle(color: FemLyraColors.period, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _isButtonEnabled() ? _verify : null,
              ),

              if (!_emailVerified || !_phoneVerified) ...[
                const SizedBox(height: 24),
                Text(
                  "Didn't receive codes?",
                  style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_emailVerified)
                      TextButton(
                        onPressed: _resendCountdown == 0 ? () => _resend('email') : null,
                        child: Text(
                          _resendCountdown == 0 ? 'Resend Email Code' : 'Resend Email in ${_resendCountdown}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: _resendCountdown == 0 ? FemLyraColors.primary : FemLyraColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (!_emailVerified && !_phoneVerified) ...[
                      const SizedBox(width: 8),
                      const Text('|', style: TextStyle(color: FemLyraColors.border)),
                      const SizedBox(width: 8),
                    ],
                    if (!_phoneVerified)
                      TextButton(
                        onPressed: _resendCountdown == 0 ? () => _resend('phone') : null,
                        child: Text(
                          _resendCountdown == 0 ? 'Resend SMS Code' : 'Resend SMS in ${_resendCountdown}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: _resendCountdown == 0 ? FemLyraColors.primary : FemLyraColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
    required bool isEnabled,
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
            enabled: isEnabled,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isEnabled ? FemLyraColors.textPrimary : FemLyraColors.textMuted,
            ),
            decoration: InputDecoration(
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FemLyraColors.border),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FemLyraColors.border, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FemLyraColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: isEnabled ? Colors.white : FemLyraColors.border.withOpacity(0.3),
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
