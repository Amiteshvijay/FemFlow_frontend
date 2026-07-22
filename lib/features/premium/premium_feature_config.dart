import 'package:flutter/material.dart';

class PremiumFeature {
  final String key;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final IconData icon;
  final String? previewImage;

  const PremiumFeature({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.icon,
    this.previewImage,
  });
}

class PremiumFeatureConfig {
  static const Map<String, PremiumFeature> features = {
    'community': PremiumFeature(
      key: 'community',
      title: 'FemLyra Community',
      subtitle: 'A safe, anonymous space to share, learn, and feel supported.',
      icon: Icons.groups_outlined,
      benefits: [
        'Join supportive wellness rooms',
        'Ask anonymous questions',
        'Share period and PMS experiences',
        'Get support from others',
        'Stay private by default',
      ],
    ),
    'wellness_score': PremiumFeature(
      key: 'wellness_score',
      title: 'Advanced Wellness Score',
      subtitle: 'Understand your mood, sleep, stress, pain, and cycle balance.',
      icon: Icons.health_and_safety_outlined,
      benefits: [
        'Personalized daily wellness score',
        'Mood and stress breakdown',
        'Pain and energy insights',
        'FemAI-powered recommendations',
        'Weekly wellness trends',
      ],
    ),
    'cycle_insights': PremiumFeature(
      key: 'cycle_insights',
      title: 'Advanced Cycle Insights',
      subtitle: 'See deeper patterns across your period, mood, symptoms, and lifestyle.',
      icon: Icons.auto_graph_outlined,
      benefits: [
        'Symptom trend analysis',
        'Cycle phase patterns',
        'PMS and mood prediction',
        'Personalized recommendations',
        'Exportable PDF reports',
      ],
    ),
    'fitness_recommendations': PremiumFeature(
      key: 'fitness_recommendations',
      title: 'Phase-Based Fitness',
      subtitle: 'Sync your workouts with your cycle for better results and energy.',
      icon: Icons.fitness_center_outlined,
      benefits: [
        'Daily exercise recommendations',
        'Phase-appropriate workout intensity',
        'Cycle-synced yoga and stretching',
        'Video guidance library',
        'Energy level optimization',
      ],
    ),
    'health_vault': PremiumFeature(
      key: 'health_vault',
      title: 'Premium Health Vault',
      subtitle: 'Advanced storage for all your medical reports and health documents.',
      icon: Icons.folder_shared_outlined,
      benefits: [
        'Unlimited document storage',
        'Categorized medical reports',
        'Direct sharing with doctors',
        'Secure biometric encryption',
        'Offline access to vault',
      ],
    ),
    'doctor_priority': PremiumFeature(
      key: 'doctor_priority',
      title: 'Priority Consultations',
      subtitle: 'Connect with expert doctors faster when you need it most.',
      icon: Icons.medical_services_outlined,
      benefits: [
        'Priority booking slots',
        'Access to top-rated specialists',
        'Extended consultation duration',
        'Follow-up message priority',
        'Detailed medical summary',
      ],
    ),
    'partner_mode': PremiumFeature(
      key: 'partner_mode',
      title: 'FemLyra Partner Mode',
      subtitle: 'Share your cycle phase and mood with your partner automatically.',
      icon: Icons.favorite_outline,
      benefits: [
        'Automatic cycle sync',
        'Mood and PMS alerts for partner',
        'Helpful tips for supportive partners',
        'Private shared calendar',
        'Simplified communication',
      ],
    ),
    'export_data': PremiumFeature(
      key: 'export_data',
      title: 'Data Export & Reports',
      subtitle: 'Generate professional health summaries for your doctor visits.',
      icon: Icons.description_outlined,
      benefits: [
        'Full cycle history export',
        'Detailed symptom & mood PDF',
        'Wellness score trend reports',
        'Custom date range selection',
        'Professional doctor-ready format',
      ],
    ),
    'pill_reminder': PremiumFeature(
      key: 'pill_reminder',
      title: 'Medication Reminders',
      subtitle: 'Never miss a dose with smart, timely notifications.',
      icon: Icons.medication_outlined,
      benefits: [
        'Custom reminder schedules',
        'Missed dose alerts',
        'History tracking',
        'Multiple medication support',
        'Cycle-synced reminders',
      ],
    ),
    'journal': PremiumFeature(
      key: 'journal',
      title: 'FemLyra Journal',
      subtitle: 'A private space to reflect on your physical and emotional journey.',
      icon: Icons.auto_stories_outlined,
      benefits: [
        'Unlimited daily entries',
        'Mood and symptom tagging',
        'Privacy-first encryption',
        'Searchable history',
        'Phase-based reflection prompts',
      ],
    ),
    'ai_chat': PremiumFeature(
      key: 'ai_chat',
      title: 'FemAI Health Chat',
      subtitle: 'Your personal AI health companion, available 24/7.',
      icon: Icons.chat_bubble_outline,
      benefits: [
        'Instant answers to health questions',
        'Cycle phase explanations',
        'Symptom-based insights',
        'Personalized wellness tips',
        'Secure and confidential',
      ],
    ),
  };

  static PremiumFeature getFeature(String key) {
    return features[key] ?? PremiumFeature(
      key: key,
      title: 'Premium Feature',
      subtitle: 'Upgrade to unlock advanced capabilities.',
      icon: Icons.star_outline,
      benefits: ['Unlock advanced insights', 'Get personalized tips', 'Support FemLyra development'],
    );
  }
}
