import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How accurate are the predictions?',
        'answer': 'FemFlow uses advanced algorithms based on your historical data. The more consistently you log, the more accurate the predictions become. However, these are estimates and should not be used for medical diagnosis or contraception.'
      },
      {
        'question': 'How does FemAI help me?',
        'answer': 'FemAI analyzes your symptoms, moods, and cycle trends to provide personalized wellness tips, explanations for how you might be feeling, and proactive health advice.'
      },
      {
        'question': 'Is my data secure?',
        'answer': 'Yes, your privacy is our priority. Your data is encrypted and we do not share your personal health information with third parties without your explicit consent.'
      },
      {
        'question': 'Can I track my flow intensity?',
        'answer': 'Absolutely. You can log flow intensity (Light, Medium, Heavy) in the "Log Period" section to help FemFlow understand your cycle better.'
      },
      {
        'question': 'What if my cycle is irregular?',
        'answer': 'FemFlow is designed to handle cycle variations. Over time, the AI learns your unique patterns even if they don\'t follow a standard 28-day cycle.'
      },
    ];

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('FAQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FemFlowColors.textPrimary,
                  ),
                ),
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                expandedAlignment: Alignment.centerLeft,
                children: [
                  Text(
                    faq['answer']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: FemFlowColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
