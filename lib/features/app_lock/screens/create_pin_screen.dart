import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../core/security/app_lock_service.dart';
import '../widgets/pin_keypad.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = "";
  String _confirmPin = "";
  bool _isConfirming = false;
  final int _pinLength = 4;
  String? _error;

  void _onKeyTap(String val) {
    if (!_isConfirming) {
      if (_pin.length < _pinLength) {
        setState(() {
          _pin += val;
          _error = null;
        });
        if (_pin.length == _pinLength) {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() => _isConfirming = true);
          });
        }
      }
    } else {
      if (_confirmPin.length < _pinLength) {
        setState(() {
          _confirmPin += val;
          _error = null;
        });
        if (_confirmPin.length == _pinLength) {
          _verifyAndSave();
        }
      }
    }
  }

  void _onDelete() {
    if (!_isConfirming) {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _verifyAndSave() async {
    if (_pin == _confirmPin) {
      final appLock = context.read<AppLockService>();
      await appLock.savePin(_pin);
      await appLock.setAppLockEnabled(true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN created successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _confirmPin = "";
        _error = "PINs do not match. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _isConfirming ? _confirmPin : _pin;
    final title = _isConfirming ? "Confirm PIN" : "Create App PIN";
    final subtitle = _isConfirming ? "Please re-enter your PIN" : "Enter a 4-digit PIN to secure your app";

    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: FemLyraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: FemLyraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < currentInput.length 
                      ? FemLyraColors.primary 
                      : FemLyraColors.border,
                  border: Border.all(color: FemLyraColors.border),
                ),
              )),
            ),
            
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: FemLyraColors.period, fontSize: 13),
              ),
            
            const Spacer(),
            
            PinKeypad(
              onKeyTap: _onKeyTap,
              onDelete: _onDelete,
              onBiometricTap: () {}, // Not used here
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
