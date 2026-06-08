import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/app_card.dart';
import 'data/referral_service.dart';
import 'models/referral_models.dart';
import 'widgets/referral_code_card.dart';
import 'widgets/referral_stats_card.dart';
import 'widgets/referral_history_card.dart';
import 'referral_history_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _service = ReferralService();
  bool _isLoading = true;
  ReferralProfile? _profile;
  List<ReferralHistoryItem> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getMyReferralInfo(),
        _service.getReferralHistory(),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as ReferralProfile;
          _history = results[1] as List<ReferralHistoryItem>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load referral details.';
        });
      }
    }
  }

  Future<void> _shareInvite() async {
    try {
      final content = await _service.getReferralShareContent();
      await Share.share(content.message, subject: content.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open share sheet.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invite Friends',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: FemFlowColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Share FemFlow.\nUnlock Premium Together.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: FemFlowColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Invite a friend to start her wellness journey with your referral code. When she joins and activates Premium, she gets 3 months free, and you also receive 3 months of Premium added to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FemFlowColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        ReferralCodeCard(code: _profile!.referralCode),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Share Invite',
                          onPressed: _shareInvite,
                        ),
                        const SizedBox(height: 32),
                        if (_profile!.invitor != null) ...[
                          _buildInvitorCard(_profile!.invitor!),
                          const SizedBox(height: 32),
                        ],
                        ReferralStatsCard(profile: _profile!),
                        const SizedBox(height: 8),
                        ReferralHistoryCard(history: _history.take(3).toList()),
                        if (_history.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReferralHistoryScreen(),
                                ),
                              ).then((_) => _fetchData());
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View All Referral History',
                                  style: TextStyle(
                                    color: FemFlowColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: FemFlowColors.primary),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        _buildHowItWorks(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStep(1, 'Share your code with friends.'),
        _buildStep(2, 'Friend signs up using your code.'),
        _buildStep(3, 'They get 3 months Premium free.'),
        _buildStep(4, 'You get 3 months added to your account!'),
      ],
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              num.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: FemFlowColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!, style: const TextStyle(color: FemFlowColors.period)),
          TextButton(onPressed: _fetchData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildInvitorCard(InvitorInfo invitor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Invited By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.textPrimary,
            ),
          ),
        ),
        AppCard(
          color: FemFlowColors.softBlush,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: FemFlowColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: FemFlowColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (invitor.mobileNo.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 14, color: FemFlowColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            invitor.mobileNo,
                            style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (invitor.email.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.email_rounded, size: 14, color: FemFlowColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              invitor.email,
                              style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
