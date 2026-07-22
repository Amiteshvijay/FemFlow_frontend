import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../providers/tips_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../premium/premium_feature_preview_screen.dart';
import './daily_tip_card.dart';

class EverydayTipsSection extends StatefulWidget {
  const EverydayTipsSection({super.key});

  @override
  State<EverydayTipsSection> createState() => _EverydayTipsSectionState();
}

class _EverydayTipsSectionState extends State<EverydayTipsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TipsProvider>().loadDailyTips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildSkeleton();
        
        if (provider.error != null) {
          return const SizedBox.shrink(); // Hide if error to maintain dashboard quality
        }
        
        final data = provider.dailyTips;
        if (data == null || data.tips.isEmpty) {
          return _buildEmptyState();
        }

        final isPremium = context.watch<SubscriptionProvider>().isPremium;
        
        // Logic: 
        // Premium: show all (usually 11)
        // Free: show 1 actual tip + 10 locked cards
        final visibleTips = isPremium ? data.tips : data.tips.take(1).toList();
        final int displayCount = isPremium ? visibleTips.length : visibleTips.length + 10;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Text(
                    'Everyday tips for you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: FemLyraColors.textPrimary,
                      letterSpacing: -0.5
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 155,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayCount,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                clipBehavior: Clip.none,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  if (index < visibleTips.length) {
                    return DailyTipCard(tip: visibleTips[index]);
                  } else {
                    return _buildLockedCard();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Everyday tips for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: FemLyraColors.blushMist.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text('Synthesizing your wellness insights...', style: TextStyle(fontSize: 14, color: FemLyraColors.textSecondary)),
              TextButton(
                onPressed: () => context.read<TipsProvider>().loadDailyTips(),
                child: const Text('Refresh', style: TextStyle(color: FemLyraColors.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 180,
          height: 24,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'cycle_insights')),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FemLyraColors.primary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FemLyraColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, color: FemLyraColors.primary, size: 24),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unlock with\nPremium',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FemLyraColors.primary,
                  ),
                ),
              ],
            ),
            // Background decorations to simulate content
            Positioned(
              bottom: 15,
              left: 15,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
