import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/subscription_provider.dart';
import 'subscription_cancelled_screen.dart';

class SubscriptionCancelOtpScreen extends StatefulWidget {
  const SubscriptionCancelOtpScreen({super.key});

  @override
  State<SubscriptionCancelOtpScreen> createState() => _SubscriptionCancelOtpScreenState();
}

class _SubscriptionCancelOtpScreenState extends State<SubscriptionCancelOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  int _resendTimer = 60;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        timer.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  Future<void> _resendOtp() async {
    final provider = context.read<SubscriptionProvider>();
    try {
      await provider.initiateCancellation();
      _startTimer();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() => _isVerifying = true);
    final provider = context.read<SubscriptionProvider>();
    try {
      await provider.verifyCancellation(otp);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionCancelledScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Verify Cancellation', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.security_rounded, color: FemLyraColors.primary, size: 48),
            const SizedBox(height: 24),
            const Text(
              'Security Verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'For your account security, please verify the 6-digit OTP sent to your registered email address.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FemLyraColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildOtpField(index)),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Confirm Cancellation',
              isLoading: _isVerifying,
              onPressed: _verify,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Didn’t receive code?', style: TextStyle(color: FemLyraColors.textSecondary)),
                TextButton(
                  onPressed: _resendTimer == 0 ? _resendOtp : null,
                  child: Text(
                    _resendTimer > 0 ? 'Resend in ${_resendTimer}s' : 'Resend Now',
                    style: TextStyle(color: _resendTimer == 0 ? FemLyraColors.primary : FemLyraColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.primary, width: 2)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_controllers.every((c) => c.text.isNotEmpty)) {
            _verify();
          }
        },
      ),
    );
  }
}
