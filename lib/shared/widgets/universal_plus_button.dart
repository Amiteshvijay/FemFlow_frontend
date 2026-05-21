import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../features/log_period/period_calendar_editor_screen.dart';
import '../../features/symptoms/symptoms_screen.dart';
import '../../features/chat/femai_chat_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/health_vault/health_vault_screen.dart';
import '../../features/wellness_score/wellness_score_dashboard_screen.dart';
import '../../features/pill_reminder/pill_reminder_list_screen.dart';
import '../../features/doctor_consultation/doctor_consultation_home_screen.dart' deferred as doctor_consultation;
import '../../features/community/community_home_screen.dart' deferred as community;
import '../../features/diet/screens/diet_home_screen.dart';
import '../../features/premium/premium_guard.dart';

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
                'Log to FemFlow',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
                children: [
                  _buildAction(context, Icons.opacity, 'Period', FemFlowColors.period, () => PeriodCalendarEditorScreen(initialStartDate: DateTime.now())),
                  _buildAction(context, Icons.sentiment_satisfied_alt, 'Symptoms', FemFlowColors.primary, () => const SymptomsScreen()),
                  _buildAction(context, Icons.auto_awesome_rounded, 'FemAI', FemFlowColors.aiWellness, () => const FemAIChatScreen(), isPremium: true, featureKey: 'ai_chat'),
                  _buildAction(context, Icons.edit_note, 'Journal', FemFlowColors.textSecondary, () => const JournalScreen(), isPremium: true, featureKey: 'journal'),
                  _buildAction(context, Icons.shield_outlined, 'Health Vault', Colors.blue, () => const HealthVaultScreen(), isPremium: true, featureKey: 'health_vault'),
                  _buildAction(context, Icons.favorite_outline, 'Wellness Score', Colors.green, () => const WellnessScoreDashboardScreen(), isPremium: true, featureKey: 'wellness_score'),
                  _buildAction(context, Icons.medication_outlined, 'Pill Reminder', Colors.orange, () => const PillReminderListScreen(), isPremium: true, featureKey: 'pill_reminder'),
                  _buildAction(context, Icons.restaurant_menu_outlined, 'Nutrition', Colors.deepOrange, () => const DietHomeScreen(), isPremium: true, featureKey: 'diet_plan'),
                  _buildDeferredAction(context, Icons.medical_services_outlined, 'Doctor', Colors.red, () async {
                    await doctor_consultation.loadLibrary();
                    return doctor_consultation.DoctorConsultationHomeScreen();
                  }),
                  _buildDeferredAction(context, Icons.groups_outlined, 'Community', Colors.teal, () async {
                    await community.loadLibrary();
                    return community.CommunityHomeScreen();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeferredAction(BuildContext context, IconData icon, String label, Color color, Future<Widget> Function() screenLoader) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        
        // Show a brief loading indicator while the library loads
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator(color: FemFlowColors.primary)),
          );
        }

        try {
          final screen = await screenLoader();
          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            if (onActionSelected != null) {
              onActionSelected!(screen);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
            }
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load feature. Please try again.')),
            );
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
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
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          if (isPremium && !hasPremium)
             Container(
               padding: const EdgeInsets.all(4),
               decoration: const BoxDecoration(
                 gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                 shape: BoxShape.circle,
               ),
               child: const Icon(Icons.lock, size: 8, color: Colors.white),
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
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
