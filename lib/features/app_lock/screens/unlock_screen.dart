import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../core/security/app_lock_service.dart';
import '../widgets/pin_keypad.dart';
import 'forgot_pin_email_screen.dart';

class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const UnlockPINView(),
        );
      },
    );
  }
}

class UnlockPINView extends StatefulWidget {
  const UnlockPINView({super.key});

  @override
  State<UnlockPINView> createState() => _UnlockPINViewState();
}

class _UnlockPINViewState extends State<UnlockPINView> {
  String _inputPin = "";
  final int _pinLength = 4;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  void _onKeyTap(String val) {
    if (_inputPin.length < _pinLength) {
      setState(() {
        _inputPin += val;
        _error = null;
      });
      
      if (_inputPin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final appLock = context.read<AppLockService>();
    final success = await appLock.verifyPin(_inputPin);
    
    if (success) {
      appLock.unlock();
    } else {
      setState(() {
        _inputPin = "";
        _error = "Incorrect PIN. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Image.asset(
              'assets/icons/femflow_app_icon_1024.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.water_drop, size: 80, color: FemFlowColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'FemFlow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: FemFlowColors.primary,
              ),
            ),
            
            const Spacer(),
            
            const Text(
              'Enter PIN to Unlock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: FemFlowColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _inputPin.length 
                      ? FemFlowColors.primary 
                      : FemFlowColors.border,
                  border: Border.all(color: FemFlowColors.border),
                ),
              )),
            ),
            
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: FemFlowColors.period, fontSize: 13),
              ),
            const Spacer(),
            
            PinKeypad(
              onKeyTap: _onKeyTap,
              onDelete: _onDelete,
              showBiometric: false, // Biometrics removed as of now
              onBiometricTap: () {},
            ),
            
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPinEmailScreen()),
                );
              },
              child: const Text(
                'Forgot PIN?',
                style: TextStyle(
                  color: FemFlowColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
