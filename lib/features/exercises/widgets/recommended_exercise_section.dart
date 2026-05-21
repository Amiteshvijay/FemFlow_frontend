import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/femflow_colors.dart';
import '../providers/exercise_provider.dart';
import '../screens/exercise_library_screen.dart';
import 'exercise_card.dart';
import '../../premium/premium_feature_preview_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../subscriptions/providers/subscription_provider.dart';

class RecommendedExerciseSection extends StatefulWidget {
  const RecommendedExerciseSection({super.key});

  @override
  State<RecommendedExerciseSection> createState() => _RecommendedExerciseSectionState();
}

class _RecommendedExerciseSectionState extends State<RecommendedExerciseSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ExerciseProvider>().loadRecommended();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        final isPremium = subscriptionProvider.isPremium;
        
        if (!isPremium) {
           return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Phase-Based Fitness',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.lock_outline, color: FemFlowColors.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'fitness_recommendations'))),
                  color: FemFlowColors.primary.withValues(alpha: 0.05),
                  border: BorderSide(color: FemFlowColors.primary.withValues(alpha: 0.2)),
                  child: const Column(
                    children: [
                      Text(
                        'Unlock daily exercise recommendations synced with your cycle phases.',
                        style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Unlock with Premium >',
                            style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
           );
        }

        return Consumer<ExerciseProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.recommended.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: FemFlowColors.primary));
            }

            if (provider.recommended.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Recommended for you',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: FemFlowColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.auto_awesome, color: FemFlowColors.aiWellness, size: 18),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
                      ),
                      child: const Text('View all', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.recommended.take(2).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExerciseCard(
                    exercise: rec.exercise,
                    recommendationReason: rec.reason,
                  ),
                )),
              ],
            );
          },
        );
      },
    );
  }
}
