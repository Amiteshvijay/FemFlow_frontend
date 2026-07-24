import 'package:flutter/material.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import '../models/doctor_models.dart';

class PrescriptionDialog extends StatelessWidget {
  final Prescription prescription;
  final String? doctorSpecialty;

  const PrescriptionDialog({
    super.key,
    required this.prescription,
    this.doctorSpecialty,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Sections Card Container
                _buildSectionsCard(),
                const SizedBox(height: 20),

                // Dashed Pink Line
                const DottedDivider(),
                const SizedBox(height: 16),

                // Signature Card
                _buildSignatureSection(),
                const SizedBox(height: 16),

                // Verification Badge
                _buildVerificationBadge(),
                const SizedBox(height: 20),

                // Close Button
                _buildCloseButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Pink Circular Rx Icon Container
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: FemLyraColors.softBlush,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.assignment_outlined,
              color: FemLyraColors.primary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Title & Underline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prescription Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: 38,
                decoration: BoxDecoration(
                  color: FemLyraColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        // Shield Icon Top Right
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: FemLyraColors.softBlush,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_outlined,
            color: FemLyraColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionsCard() {
    final items = <Widget>[];

    // 1. Diagnosis
    if (prescription.diagnosis.isNotEmpty) {
      items.add(
        _buildSectionItem(
          icon: Icons.medical_services_outlined,
          title: 'Diagnosis',
          content: prescription.diagnosis,
        ),
      );
    }

    // 2. Medicines
    if (prescription.medicines.isNotEmpty) {
      final formattedMedicines = prescription.medicines.map((m) {
        if (m is Map) {
          final name = m['name'] ?? 'Medicine';
          final dosage = m['dosage'] != null ? ' (${m['dosage']})' : '';
          final frequency = m['frequency'] != null ? ' - ${m['frequency']}' : '';
          return '• $name$dosage$frequency';
        }
        return '• $m';
      }).join('\n');

      items.add(
        _buildSectionItem(
          icon: Icons.medication_outlined,
          title: 'Medicines',
          content: formattedMedicines,
        ),
      );
    }

    // 3. Instructions
    if (prescription.instructions != null && prescription.instructions!.trim().isNotEmpty) {
      items.add(
        _buildSectionItem(
          icon: Icons.assignment_outlined,
          title: 'Instructions',
          content: prescription.instructions!,
        ),
      );
    }

    // 4. Precautions
    if (prescription.precautions != null && prescription.precautions!.trim().isNotEmpty) {
      items.add(
        _buildSectionItem(
          icon: Icons.shield_outlined,
          title: 'Precautions',
          content: prescription.precautions!,
        ),
      );
    }

    // 5. Lifestyle Recommendations
    if (prescription.lifestyleRecommendations != null && prescription.lifestyleRecommendations!.trim().isNotEmpty) {
      items.add(
        _buildSectionItem(
          icon: Icons.monitor_heart_outlined,
          title: 'Lifestyle Recommendations',
          content: prescription.lifestyleRecommendations!,
        ),
      );
    }

    // 6. Next Consultation
    if (prescription.nextConsultationRecommendation != null && prescription.nextConsultationRecommendation!.trim().isNotEmpty) {
      items.add(
        _buildSectionItem(
          icon: Icons.calendar_month_outlined,
          title: 'Next Consultation',
          content: prescription.nextConsultationRecommendation!,
        ),
      );
    }

    // Combine with dividers
    final childrenWithDividers = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      childrenWithDividers.add(items[i]);
      if (i < items.length - 1) {
        childrenWithDividers.add(
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: childrenWithDividers,
      ),
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FemLyraColors.softBlush,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: FemLyraColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    final docName = prescription.doctorName.startsWith('Dr.')
        ? prescription.doctorName
        : 'Dr. ${prescription.doctorName}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FemLyraColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Authorized Signature / Stamp',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Signature Box
              Container(
                height: 54,
                width: 120,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: prescription.signatureStampUrl != null &&
                        prescription.signatureStampUrl!.isNotEmpty
                    ? Image.network(
                        prescription.signatureStampUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackSignature(docName),
                      )
                    : _buildFallbackSignature(docName),
              ),
              const SizedBox(width: 14),
              // Doctor Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MBBS',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      doctorSpecialty ?? 'General Physician',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Reg. No. 12345',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackSignature(String name) {
    return Center(
      child: Text(
        name,
        style: TextStyle(
          fontFamily: 'Cursive',
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.teal.shade700,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_outlined,
          size: 15,
          color: FemLyraColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          'This prescription is digitally generated & verified.',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: FemLyraColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Close',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DottedDivider({
    super.key,
    this.height = 1,
    this.color = const Color(0xFFF8BBD0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
