import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: FemLyraColors.period),
            const SizedBox(height: 24),
            const Text('Are you sure?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Deleting your account is permanent and will remove all your cycle data. This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FemLyraColors.textSecondary),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Delete My Account',
              backgroundColor: FemLyraColors.period,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This feature will be available soon.')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
