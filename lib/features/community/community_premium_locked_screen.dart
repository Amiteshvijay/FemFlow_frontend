import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/community_models.dart';

class CommunityPremiumLockedScreen extends StatelessWidget {
  final CommunityPreview preview;

  const CommunityPremiumLockedScreen({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: FemLyraColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          preview.title,
          style: const TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_person_rounded, size: 80, color: FemLyraColors.primary),
            const SizedBox(height: 24),
            Text(
              preview.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: FemLyraColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildLockedCard(),
            const SizedBox(height: 32),
            _buildBenefitsList(),
            const SizedBox(height: 32),
            _buildRoomsPreview(),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Upgrade to Premium',
              onPressed: () {
                // TODO: Navigate to PremiumPlanScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium plans coming soon!'))
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: FemLyraColors.textMuted)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Community support is not medical advice.',
              style: TextStyle(fontSize: 11, color: FemLyraColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FemLyraColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FemLyraColors.primary.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.stars_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Community is included with FemLyra Premium.',
              style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Why join our community?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...preview.benefits.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(b, style: const TextStyle(fontSize: 14, color: FemLyraColors.textSecondary))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRoomsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Featured Rooms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: preview.roomsPreview.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(r, style: const TextStyle(fontSize: 13, color: FemLyraColors.textMuted)),
          )).toList(),
        ),
      ],
    );
  }
}
