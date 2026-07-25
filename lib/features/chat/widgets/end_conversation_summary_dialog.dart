import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';

class EndConversationSummaryDialog extends StatelessWidget {
  final int totalTurns;
  final String languageName;
  final VoidCallback onConfirmEnd;

  const EndConversationSummaryDialog({
    super.key,
    required this.totalTurns,
    required this.languageName,
    required this.onConfirmEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.check_circle_outline_rounded, color: FemLyraColors.primary, size: 28),
          SizedBox(width: 10),
          Text("End Conversation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thank you for speaking with FemAI. Your session summary is saved securely in your chat history.",
            style: TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FemLyraColors.softBlush,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Language:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(languageName, style: const TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Exchanges:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("$totalTurns turns", style: const TextStyle(color: FemLyraColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Resume", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirmEnd();
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: FemLyraColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("End Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
