import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'models/tips_models.dart';
import 'providers/tips_provider.dart';
import 'data/tips_service.dart';
import '../exercises/screens/exercise_home_screen.dart';
import '../subscriptions/widgets/premium_feature_locked_widget.dart';

class TipsDetailScreen extends StatefulWidget {
  final String tipKey;

  const TipsDetailScreen({
    super.key,
    required this.tipKey,
  });

  @override
  State<TipsDetailScreen> createState() => _TipsDetailScreenState();
}

class _TipsDetailScreenState extends State<TipsDetailScreen> {
  late Future<DailyTipDetailModel?> _detailFuture;
  final TipsService _tipsService = TipsService();
  bool? _isSavedLocally;

  @override
  void initState() {
    super.initState();
    _detailFuture = context.read<TipsProvider>().getTipDetail(widget.tipKey);
  }

  Future<void> _handleSave(DailyTipDetailModel tip) async {
    try {
      final newStatus = await _tipsService.toggleSaveTip(tip.id);
      setState(() {
        _isSavedLocally = newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Tip saved to your profile' : 'Tip removed from saved'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update tip status')),
        );
      }
    }
  }

  Future<void> _handleShare(DailyTipDetailModel tip) async {
    final String shareContent = "${tip.title}\n\n${tip.subtitle}\n\n${tip.detail}\n\nShared via FemFlow 🌸";
    await Share.share(shareContent, subject: tip.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: FutureBuilder<DailyTipDetailModel?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FemFlowColors.primary));
          }
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('403') || error.contains('PREMIUM_REQUIRED')) {
               return _buildLockedState();
            }
            return _buildErrorState();
          }
          if (snapshot.data == null) {
            return _buildErrorState();
          }
          return _buildContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DailyTipDetailModel tip) {
    final phaseColor = _getPhaseColor(tip.phase);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(tip, phaseColor),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAISummary(tip),
                const SizedBox(height: 24),
                if (tip.whyItMatters.isNotEmpty) ...[
                  _buildSectionHeader('Why it matters', Icons.lightbulb_outline, Colors.orange),
                  const SizedBox(height: 12),
                  Text(tip.whyItMatters, style: const TextStyle(fontSize: 16, height: 1.6, color: FemFlowColors.textPrimary)),
                  const SizedBox(height: 32),
                ],
                if (tip.whatToDo.isNotEmpty) ...[
                  _buildSectionHeader('What you can do today', Icons.check_circle_outline, Colors.green),
                  const SizedBox(height: 16),
                  ...tip.whatToDo.map((item) => _buildActionItem(item, phaseColor)),
                  const SizedBox(height: 32),
                ],
                if (tip.categoryKey == 'recommended_exercises') ...[
                  _buildExerciseSection(context, tip),
                  const SizedBox(height: 32),
                ],
                _buildInteractions(tip),
                const SizedBox(height: 40),
                _buildSafetyDisclaimer(tip.categoryKey),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(DailyTipDetailModel tip, Color phaseColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: phaseColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [phaseColor, phaseColor.withValues(alpha: 0.8)],
            ),
          ),
          child: Stack(
            children: [
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Day ${tip.cycleDay ?? "--"} • ${tip.phase?.toUpperCase() ?? "GENERAL"}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip.title,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      tip.subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAISummary(DailyTipDetailModel tip) {
    return AppCard(
      color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI PERSONALIZED INSIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FemFlowColors.aiWellness, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Text(
            tip.aiInsight ?? "Your body is moving through its natural rhythm. Supporting it with kindness is the best focus for today.",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: FemFlowColors.textPrimary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Text(
            tip.detail,
            style: const TextStyle(fontSize: 15, height: 1.6, color: FemFlowColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
      ],
    );
  }

  Widget _buildActionItem(String text, Color phaseColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: phaseColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.add, size: 14, color: phaseColor),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: FemFlowColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(BuildContext context, DailyTipDetailModel tip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseHomeScreen())),
              child: const Text('View all', style: TextStyle(color: FemFlowColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseHomeScreen())),
          child: const Row(
            children: [
              Icon(Icons.play_circle_fill, color: FemFlowColors.primary, size: 48),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Today\'s Routine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Cycle-synced movement for your current energy', style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractions(DailyTipDetailModel tip) {
    final bool currentSavedStatus = _isSavedLocally ?? tip.isSaved;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleSave(tip),
            icon: Icon(currentSavedStatus ? Icons.bookmark : Icons.bookmark_border),
            label: Text(currentSavedStatus ? 'Saved' : 'Save Tip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: currentSavedStatus ? FemFlowColors.primary : FemFlowColors.textPrimary,
              elevation: 0,
              side: BorderSide(color: currentSavedStatus ? FemFlowColors.primary : Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleShare(tip),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: FemFlowColors.textPrimary,
              elevation: 0,
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyDisclaimer(String categoryKey) {
    String disclaimer = 'FemFlow provides educational wellness guidance and is not a medical diagnosis.';
    if (categoryKey == 'pregnancy_chance') {
      disclaimer += ' This prediction should not be used for contraception or fertility treatment decisions.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: FemFlowColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(disclaimer, style: const TextStyle(fontSize: 13, color: FemFlowColors.textMuted, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: PremiumFeatureLockedWidget(
            title: 'Unlock Personalized Tips',
            description: 'Upgrade to FemFlow Premium to unlock all 11 AI-personalized daily wellness cards.',
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: BackButton(color: Colors.black)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Could not load personalized insight', style: TextStyle(color: Colors.grey)),
            TextButton(onPressed: () => setState(() { _detailFuture = context.read<TipsProvider>().getTipDetail(widget.tipKey); }), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor(String? phase) {
    switch (phase?.toLowerCase()) {
      case 'menstrual': return FemFlowColors.period;
      case 'follicular': return FemFlowColors.primary;
      case 'ovulatory': return FemFlowColors.ovulation;
      case 'luteal': return Colors.orange;
      default: return FemFlowColors.primary;
    }
  }
}
