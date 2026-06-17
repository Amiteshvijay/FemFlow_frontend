import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/storage/token_storage.dart';
import '../auth/providers/auth_provider.dart';
import 'data/partner_service.dart';

class AcceptInviteScreen extends StatefulWidget {
  final String token;
  final String email;
  final String? pairingCode;

  const AcceptInviteScreen({
    super.key,
    required this.token,
    required this.email,
    this.pairingCode,
  });

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  late final TextEditingController _pairingCodeController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final PartnerService _partnerService = PartnerService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _pairingCodeController = TextEditingController(text: widget.pairingCode);
  }

  @override
  void dispose() {
    _pairingCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvite() async {
    final pairingCode = _pairingCodeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (pairingCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pairing code')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _partnerService.acceptInvite(
        token: widget.token,
        pairingCode: pairingCode,
        password: password,
      );

      final String? access = response['access'];
      final String? refresh = response['refresh'];
      if (access != null && refresh != null) {
        await TokenStorage().saveTokens(access: access, refresh: refresh);
      }

      if (mounted) {
        context.read<AuthProvider>().notifyLogin();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted successfully!')),
        );
        // Navigate to home or shell
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept invitation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Accept Invitation'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite, size: 64, color: FemFlowColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Join Your Partner',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'You have been invited to support your partner on FemFlow. Enter your pairing code and create a password to set up your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Text(
              'Email: ${widget.email}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pairingCodeController,
              decoration: const InputDecoration(
                labelText: 'Pairing Code',
                border: OutlineInputBorder(),
                hintText: 'Enter 6-digit pairing code',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Create Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Accept & Create Account',
              onPressed: _acceptInvite,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
