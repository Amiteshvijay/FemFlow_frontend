import 'package:flutter/material.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/shared/widgets/primary_button.dart';
import '../data/doctor_consultation_service.dart';
import '../models/doctor_models.dart';

class DoctorReviewBottomSheet extends StatefulWidget {
  final DoctorBooking booking;

  const DoctorReviewBottomSheet({super.key, required this.booking});

  @override
  State<DoctorReviewBottomSheet> createState() => _DoctorReviewBottomSheetState();
}

class _DoctorReviewBottomSheetState extends State<DoctorReviewBottomSheet> {
  final DoctorConsultationService _service = DoctorConsultationService();
  int _rating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _tags = [
    'Helpful', 'Friendly', 'Explained Clearly', 
    'Professional', 'Good Listener', 'Late Response', 
    'Rushed Consultation'
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.submitReview(
        bookingId: widget.booking.id,
        rating: _rating,
        quickTags: _selectedTags,
        reviewText: _reviewController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully! Thank you for your feedback.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rate Your Consultation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDoctorHeader(),
            const SizedBox(height: 32),
            const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildStarRating(),
            const SizedBox(height: 32),
            const Text('What went well?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildQuickTags(),
            const SizedBox(height: 32),
            const Text('Share more about your experience (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Tell us how the doctor helped you...',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FemFlowColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: FemFlowColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.booking.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.booking.doctorSpecialty ?? 'Specialist', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () => setState(() => _rating = index + 1),
          icon: Icon(
            index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
    );
  }

  Widget _buildQuickTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return InkWell(
          onTap: () => _toggleTag(tag),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? FemFlowColors.primary : Colors.white,
              border: Border.all(color: isSelected ? FemFlowColors.primary : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
