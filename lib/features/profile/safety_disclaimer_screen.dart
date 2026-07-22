import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyDisclaimerScreen extends StatelessWidget {
  const SafetyDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Safety Disclaimer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Important Notice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: FemLyraColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FemLyra and FemAI are designed to provide educational information and cycle tracking assistance only. Important: FemLyra is NOT a medical device and does not diagnose, treat, cure, or prevent any medical condition. The content and insights provided are not intended to be a substitute for professional medical advice, diagnosis, or treatment.',
                    style: TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildDisclaimerPoint(
                    'Seek Professional Advice',
                    'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have read on FemLyra.',
                  ),
                  _buildDisclaimerPoint(
                    'No Contraceptive Guarantee',
                    'Cycle predictions are based on statistical probability and should not be used as a primary method of birth control or to prevent pregnancy.',
                  ),
                  _buildDisclaimerPoint(
                    'Accuracy',
                    'While we strive for accuracy, body patterns can vary due to stress, illness, travel, or other factors. Never ignore professional medical advice because of something you have read on this app.',
                  ),
                  _buildDisclaimerPoint(
                    'Emergency',
                    'If you think you may have a medical emergency, call your doctor or emergency services immediately.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://www.femlyra.com/safety-disclaimer');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'Click here to know more about our Safety Disclaimer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: FemLyraColors.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'By using FemLyra, you acknowledge and agree to these terms.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerPoint(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: FemLyraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: FemLyraColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
