import 'package:femlyra/core/config/brand_config.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import './providers/auth_provider.dart';
import 'data/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'two_factor_otp_screen.dart';
import '../../core/services/version_service.dart';
import 'widgets/update_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final VersionService _versionService = VersionService();

  @override
  void initState() {
    super.initState();
    _checkAppUpdate();
  }

  Future<void> _checkAppUpdate() async {
    // Only check if we're on the login screen to prompt for update
    final updateInfo = await _versionService.checkUpdate();
    if (updateInfo != null && updateInfo.updateAvailable && mounted) {
      showDialog(
        context: context,
        barrierDismissible: updateInfo.updateType != 'mandatory',
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        if (result.requires2fa) {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (_) => TwoFactorOtpScreen(
                 twoFactorToken: result.twoFactorToken!,
                 maskedEmail: result.maskedEmail!,
               ),
             ),
           );
        } else {
           if (mounted) {
             context.read<AuthProvider>().notifyLogin();
           }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Clean up common technical prefixes
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
        errorMessage = errorMessage.replaceAll('ApiException:', '').trim();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: FemLyraColors.period,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo and Branding
              Column(
                children: [
                  Image.asset(
                    'assets/icons/app_logo_final.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, size: 80, color: FemLyraColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    BrandConfig.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: FemLyraColors.primary,
                    ),
                  ),
                  const Text(
                    BrandConfig.tagline,
                    style: TextStyle(
                      fontSize: 16,
                      color: FemLyraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_outline, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Privacy-First & Secure',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Form
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Email or Mobile Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: FemLyraColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: FemLyraColors.border),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Login',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: FemLyraColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
