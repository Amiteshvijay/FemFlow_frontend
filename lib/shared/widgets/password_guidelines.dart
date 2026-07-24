import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';

class PasswordGuidelines extends StatelessWidget {
  final String password;

  const PasswordGuidelines({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final hasMinMax = password.length >= 8 && password.length <= 20;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FemLyraColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Hints',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: FemLyraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildRuleItem('8 to 20 characters', hasMinMax),
          const SizedBox(height: 6),
          _buildRuleItem('At least 1 uppercase letter (A-Z)', hasUppercase),
          const SizedBox(height: 6),
          _buildRuleItem('At least 1 lowercase letter (a-z)', hasLowercase),
          const SizedBox(height: 6),
          _buildRuleItem('At least 1 number (0-9)', hasNumber),
          const SizedBox(height: 6),
          _buildRuleItem('At least 1 special character (e.g. !@#\$%)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isMet ? Colors.green : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? Colors.green.shade700 : FemLyraColors.textSecondary,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
