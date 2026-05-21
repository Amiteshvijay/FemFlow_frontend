import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/referral_service.dart';

class ReferralCodeEntryScreen extends StatefulWidget {
  final bool isFromOnboarding;

  const ReferralCodeEntryScreen({super.key, this.isFromOnboarding = false});

  @override
  State<ReferralCodeEntryScreen> createState() => _ReferralCodeEntryScreenState();
}

class _ReferralCodeEntryScreenState extends State<ReferralCodeEntryScreen> {
  final ReferralService _service = ReferralService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.applyReferralCode(code);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral applied! You unlocked 3 months Premium.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
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
        title: const Text('Redeem Referral', style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: FemFlowColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Have a referral code?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter a friend’s code to unlock 3 months FemFlow Premium free.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FemFlowColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 40),
            
            if (!_isSuccess) ...[
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter code (e.g. FEM7K2A9Q)',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Apply Code',
                isLoading: _isLoading,
                onPressed: _applyCode,
              ),
              if (widget.isFromOnboarding)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip for now', style: TextStyle(color: FemFlowColors.textSecondary)),
                ),
            ] else
              const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Premium unlocked for 3 months!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
