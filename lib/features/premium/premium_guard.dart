import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../subscriptions/providers/subscription_provider.dart';
import 'premium_feature_preview_screen.dart';

class PremiumGuard {
  static Future<void> openPremiumFeature({
    required BuildContext context,
    required String featureKey,
    required Widget premiumScreen,
  }) async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    
    // Safety: check if status is loaded
    if (subscriptionProvider.status == null) {
      await subscriptionProvider.loadStatus();
    }

    if (subscriptionProvider.isPremium) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => premiumScreen),
        );
      }
    } else {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PremiumFeaturePreviewScreen(featureKey: featureKey),
          ),
        );
      }
    }
  }

  static bool isPremium(BuildContext context) {
    return context.read<SubscriptionProvider>().isPremium;
  }
}
