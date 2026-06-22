import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/subscription_provider.dart';
import '../../referrals/referral_code_entry_screen.dart';
import '../models/subscription_models.dart';
import './payment_screen.dart';

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  int _selectedPlanIndex = 2; // Default to 12 Months (Index 2)

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<SubscriptionProvider>().loadPlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.plans.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: FemFlowColors.primary));
          }

          // Ensure index is within range if plans loaded
          if (_selectedPlanIndex >= provider.plans.length) {
            _selectedPlanIndex = provider.plans.length - 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildTrialBanner(provider),
                const SizedBox(height: 32),
                const Text(
                  'Choose your plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(provider.plans.length, (index) {
                  return _buildPlanCard(provider.plans[index], index);
                }),
                const SizedBox(height: 24),
                _buildReferralSection(provider),
                const SizedBox(height: 32),
                _buildFeatureList(),
                const SizedBox(height: 40),
                _buildSubscribeButton(provider),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Cancel anytime. Secure payment via Razorpay.',
                    style: TextStyle(color: FemFlowColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FemFlow Premium',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: FemFlowColors.primary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Unlock personalized cycle insights, FemAI guidance, and deeper wellness tracking.',
          style: TextStyle(fontSize: 16, color: FemFlowColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTrialBanner(SubscriptionProvider provider) {
    if (provider.status?.status == 'trial_active') {
       return AppCard(
         color: Colors.green.withValues(alpha: 0.1),
         border: const BorderSide(color: Colors.green, width: 0.5),
         child: Row(
           children: [
             const Icon(Icons.verified_outlined, color: Colors.green),
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 'You are currently on Premium trial — ${provider.status!.trialDaysLeft} days left',
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
               ),
             ),
           ],
         ),
       );
    }

    if (provider.status?.status == 'free' && provider.status?.hasUsedTrial == false) {
      return AppCard(
        color: FemFlowColors.blushMist.withValues(alpha: 0.5),
        border: const BorderSide(color: FemFlowColors.primary, width: 1),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1-Month Free Trial',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                  ),
                  Text(
                    'For new members. No charge today.',
                    style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index) {
    bool isSelected = _selectedPlanIndex == index;
    
    // Highlight logic based on user rules
    bool isStrongHighlight = plan.highlight;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlanIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? FemFlowColors.primary : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: FemFlowColors.primary.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isStrongHighlight 
                        ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])
                        : LinearGradient(colors: [FemFlowColors.primary, FemFlowColors.primary.withValues(alpha: 0.7)]),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    plan.badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isSelected ? FemFlowColors.primary : FemFlowColors.textPrimary,
                                ),
                              ),
                              Text(
                                plan.durationLabel ?? plan.billingCycle,
                                style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${plan.offerPrice?.toInt() ?? plan.price.toInt()}',
                                  style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? FemFlowColors.primary : FemFlowColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    plan.isLifetime ? 'one-time' : '/${plan.billingCycle}',
                                    style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (plan.offerPrice != null)
                              Text(
                                '₹${plan.price.toInt()}',
                                style: const TextStyle(
                                  fontSize: 14, 
                                  color: FemFlowColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (plan.secondaryLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          plan.secondaryLabel!,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    if (isSelected) ...[
                      const Divider(height: 32),
                      ...plan.benefits.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: FemFlowColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(b, style: const TextStyle(fontSize: 13, color: FemFlowColors.textPrimary))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Premium includes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _featureItem('FemAI personalized health guidance'),
        _featureItem('Advanced cycle analytics'),
        _featureItem('Wellness score breakdown'),
        _featureItem('Symptom and mood trends'),
        _featureItem('Phase-synced exercise plans'),
        _featureItem('Unlimited Health Vault storage'),
        _featureItem('FemFlow Community access'),
        _featureItem('Export health reports (PDF)'),
      ],
    );
  }

  Widget _featureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: FemFlowColors.primary, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider provider) {
    bool isFree = provider.status?.status == 'free' && provider.status?.hasUsedTrial == false;
    final selectedPlan = provider.plans[_selectedPlanIndex];

    String label = 'Subscribe Now';
    if (isFree) {
      label = 'Start 1-Month Free Trial';
    } else if (selectedPlan.isLifetime) {
      label = 'Get Lifetime Premium';
    } else if (selectedPlan.planKey == 'yearly') {
      label = 'Start Yearly';
    } else if (selectedPlan.planKey == 'monthly') {
      label = 'Start Monthly';
    } else if (selectedPlan.planKey == 'quarterly') {
      label = 'Start 3 Months';
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: PrimaryButton(
        label: label,
        isLoading: provider.isLoading,
        onPressed: () => _handleAction(provider),
      ),
    );
  }

  void _handleAction(SubscriptionProvider provider) async {
    if (provider.status?.status == 'free' && provider.status?.hasUsedTrial == false) {
      final success = await provider.startTrial();
      if (success && mounted) {
        _showSuccessScreen(isTrial: true);
      }
    } else {
      final selectedPlan = provider.plans[_selectedPlanIndex];
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(plan: selectedPlan)),
      );
      if (result == true && mounted) {
        _showSuccessScreen(plan: selectedPlan);
      }
    }
  }

  void _showSuccessScreen({bool isTrial = false, SubscriptionPlan? plan}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded, color: FemFlowColors.primary, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to FemFlow Premium 🌸',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isTrial 
                ? 'Your 1-Month Free Trial is now active.'
                : (plan?.isLifetime == true 
                    ? 'Lifetime Premium is now active on your account.'
                    : 'Your ${plan?.name} is active.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: FemFlowColors.textSecondary),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection(SubscriptionProvider provider) {
    final bool hasAppliedReferral = provider.status?.status == 'active' && provider.status?.planKey == 'referral_bonus';

    return AppCard(
      color: FemFlowColors.ovulation.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.ovulation, width: 0.5),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: FemFlowColors.ovulation),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Have a referral code?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (hasAppliedReferral)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAppliedReferral)
             Text(
               'Referral reward active! Premium valid until ${DateFormat('MMM d, yyyy').format(provider.status!.subscriptionEndDate!)}',
               style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
             )
          else ...[
            const Text(
              'Enter a friend\'s code to unlock 3 months Premium free.',
              style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReferralCodeEntryScreen()),
                  );
                  if (result == true) {
                    provider.loadStatus();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: FemFlowColors.ovulation,
                  side: const BorderSide(color: FemFlowColors.ovulation),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Enter Referral Code'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
