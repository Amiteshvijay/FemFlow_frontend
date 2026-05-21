import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';

class SecureLoadingScreen extends StatelessWidget {
  const SecureLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: FemFlowColors.primary),
            SizedBox(height: 16),
            Text(
              'Securing your data...',
              style: TextStyle(
                color: FemFlowColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
