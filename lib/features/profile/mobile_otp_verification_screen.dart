import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/profile_service.dart';

class MobileOtpVerificationScreen extends StatefulWidget {
  final String mobileNumber;

  const MobileOtpVerificationScreen({super.key, required this.mobileNumber});

  @override
  State<MobileOtpVerificationScreen> createState() => _MobileOtpVerificationScreenState();
}

class _MobileOtpVerificationScreenState extends State<MobileOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _profileService.verifyMobileOtp(
        mobileNumber: widget.mobileNumber,
        otp: otp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mobile number verified successfully'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: FemLyraColors.period),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.sendMobileOtp(widget.mobileNumber);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: $e'), backgroundColor: FemLyraColors.period),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Verify Mobile Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the OTP sent to ${widget.mobileNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: FemLyraColors.textSecondary),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FemLyraColors.border),
                ),
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Verify OTP',
              onPressed: _verifyOtp,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _canResend ? _resendOtp : null,
              child: Text(
                _canResend ? 'Resend OTP' : 'Resend OTP in $_secondsRemaining seconds',
                style: TextStyle(color: _canResend ? FemLyraColors.primary : FemLyraColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
