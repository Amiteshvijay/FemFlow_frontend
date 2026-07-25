import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/FemLyra_colors.dart';

class EmergencyActionCard extends StatelessWidget {
  final String emergencyMessage;
  final VoidCallback onConsultDoctor;
  final VoidCallback onDismiss;

  const EmergencyActionCard({
    super.key,
    required this.emergencyMessage,
    required this.onConsultDoctor,
    required this.onDismiss,
  });

  Future<void> _makeEmergencyCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '108');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      debugPrint('Failed to make emergency call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                "Medical Alert",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            emergencyMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A1515),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: onConsultDoctor,
                icon: const Icon(Icons.medical_services_rounded, size: 18),
                label: const Text("Consult a Doctor"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemLyraColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _makeEmergencyCall,
                icon: const Icon(Icons.call_rounded, color: Colors.redAccent, size: 18),
                label: const Text("Call Emergency Help (108)", style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: onDismiss,
                child: const Text("Continue Conversation", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
