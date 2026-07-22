import 'package:flutter/material.dart';
import '../../../../core/theme/FemLyra_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class DoctorAdviceCard extends StatelessWidget {
  final bool isEnabled;
  final String? doctorName;
  final String? adviceNotes;
  final List<String> medicalConditions;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const DoctorAdviceCard({
    super.key,
    required this.isEnabled,
    this.doctorName,
    this.adviceNotes,
    required this.medicalConditions,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services_outlined, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doctor Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Clinical personalization', style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeThumbColor: FemLyraColors.primary,
                  activeTrackColor: FemLyraColors.primary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          if (isEnabled) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (doctorName != null && doctorName!.isNotEmpty) ...[
                      Text('Doctor: $doctorName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                    ],
                    if (adviceNotes != null && adviceNotes!.isNotEmpty) ...[
                      Text(
                        adviceNotes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: FemLyraColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (medicalConditions.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children: medicalConditions.map((condition) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FemLyraColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: FemLyraColors.primary.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            condition.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Row(
                      children: [
                        Text('Edit Advice Details', style: TextStyle(fontSize: 13, color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: FemLyraColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
