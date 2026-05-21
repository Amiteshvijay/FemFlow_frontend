import 'package:flutter/material.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:femflow/shared/widgets/app_card.dart';
import 'package:intl/intl.dart';
import 'models/doctor_models.dart';
import 'doctor_booking_screen.dart';

import 'data/doctor_consultation_service.dart';

class DoctorDetailScreen extends StatefulWidget {
  final DoctorProfile doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  late DoctorProfile _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    try {
      final fullDoctor = await _service.getDoctorDetail(widget.doctor.id);
      if (mounted) {
        setState(() {
          _doctor = fullDoctor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Doctor Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _doctor.profileImage != null ? NetworkImage(_doctor.profileImage!) : null,
                  child: _doctor.profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _doctor.fullName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_doctor.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.green, size: 20),
                          ],
                        ],
                      ),
                      Text(_doctor.speciality, style: TextStyle(color: FemFlowColors.primary, fontSize: 14)),
                      Text(_doctor.qualification, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('${_doctor.experienceYears} years experience', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rating & Fee Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      _doctor.rating?.toString() ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text('(${_doctor.totalReviews} reviews)', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Consultation Fee', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '₹${_doctor.consultationFee.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading && _doctor.about == null)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ))
            else ...[
              // About Section
              const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _doctor.about ?? 'No information available.',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // Registration Info
              if (_doctor.registrationNumber != null || _doctor.medicalCouncil != null) ...[
                const Text('Medical Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_doctor.registrationNumber != null)
                          _buildInfoRow(Icons.badge_outlined, 'Registration No', _doctor.registrationNumber!),
                        if (_doctor.registrationNumber != null && _doctor.medicalCouncil != null)
                          const Divider(height: 16),
                        if (_doctor.medicalCouncil != null)
                          _buildInfoRow(Icons.account_balance_outlined, 'Medical Council', _doctor.medicalCouncil!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Education History
              if (_doctor.educationHistory.isNotEmpty) ...[
                const Text('Education', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._doctor.educationHistory.map((edu) => _buildExperienceItem(
                  edu['institution'] ?? 'Institution',
                  edu['degree'] ?? 'Degree',
                  edu['year'] ?? '',
                  Icons.school_outlined,
                )),
                const SizedBox(height: 24),
              ],

              // Work History
              if (_doctor.workHistory.isNotEmpty) ...[
                const Text('Experience & Work History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._doctor.workHistory.map((work) => _buildExperienceItem(
                  work['organization'] ?? 'Organization',
                  work['designation'] ?? 'Designation',
                  work['duration'] ?? '',
                  Icons.work_outline,
                )),
                const SizedBox(height: 24),
              ],

              // Languages
              const Text('Languages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _doctor.languages.map((lang) => Chip(
                  label: Text(lang, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide.none,
                )).toList(),
              ),
              const SizedBox(height: 24),

              // Consultation Modes
              const Text('Available Modes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _doctor.consultationModes.map((mode) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Icon(_getModeIcon(mode), size: 18, color: FemFlowColors.primary),
                      const SizedBox(width: 4),
                      Text(mode.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 32),

              // Patient Reviews Section
              if (_doctor.recentReviews.isNotEmpty) ...[
                const Text('Patient Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._doctor.recentReviews.map((review) => _buildReviewCard(review)),
                const SizedBox(height: 24),
              ],
            ],

            // Safety Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'If you have severe bleeding, fainting, chest pain, pregnancy bleeding, or severe pain, seek urgent medical care.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 80), // Space for sticky button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DoctorBookingScreen(doctor: _doctor)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: FemFlowColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Book Now - ₹${_doctor.consultationFee.toInt()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(DoctorReview review) {
    String formattedDate = 'Recent';
    try {
      formattedDate = DateFormat('d MMM yyyy').format(DateTime.parse(review.createdAt));
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review.userName.isNotEmpty ? review.userName : 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              if (review.bookingIdDisplay != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Booking ID: ${review.bookingIdDisplay}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              if (review.quickTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: review.quickTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FemFlowColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 10, color: FemFlowColors.primary)),
                  )).toList(),
                ),
              ],
              if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  review.reviewText!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
              if (review.doctorResponse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Doctor Response', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(review.doctorResponse!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildExperienceItem(String title, String subtitle, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: FemFlowColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.phone;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.help_outline;
    }
  }
}
