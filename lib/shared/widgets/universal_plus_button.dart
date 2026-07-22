import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';

import '../../features/symptoms/symptoms_screen.dart';
import '../../features/doctor_consultation/doctor_consultation_home_screen.dart';
import '../../features/premium/premium_guard.dart';
import '../../features/lab_tests/lab_tests_home_screen.dart';

class UniversalPlusButton extends StatelessWidget {
  final VoidCallback? onLogged;
  final Function(Widget)? onActionSelected;

  const UniversalPlusButton({super.key, this.onLogged, this.onActionSelected});

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log to FemLyra',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.8,
                children: [
                  _buildAction(
                    context, 
                    Icons.science_outlined, 
                    'Lab Test', 
                    FemFlowColors.primary, 
                    () => const LabTestsHomeScreen()
                  ),
                  _buildAction(
                    context, 
                    Icons.sentiment_satisfied_alt, 
                    'Symptoms', 
                    FemFlowColors.primary, 
                    () => const SymptomsScreen()
                  ),
                  _buildAction(
                    context, 
                    Icons.medical_services_outlined, 
                    'Doctor', 
                    Colors.red, 
                    () => const DoctorConsultationHomeScreen()
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, String label, Color color, Widget Function() screenBuilder, {bool isPremium = false, String? featureKey}) {
    final hasPremium = PremiumGuard.isPremium(context);
    
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (isPremium && !hasPremium && featureKey != null) {
          PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: featureKey, 
            premiumScreen: screenBuilder()
          );
          return;
        }

        if (onActionSelected != null) {
          onActionSelected!(screenBuilder());
        } else {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => screenBuilder()));
          if (result == true && onLogged != null) {
            onLogged!();
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label, 
            textAlign: TextAlign.center, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FemFlowColors.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showActionSheet(context),
      child: RepaintBoundary(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: FemFlowColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: FemFlowColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/FemLyra_app_icon_1024.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
