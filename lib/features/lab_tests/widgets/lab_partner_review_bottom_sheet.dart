import 'package:flutter/material.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:femflow/core/network/api_client.dart';
import 'package:femflow/shared/widgets/primary_button.dart';
import 'package:femflow/features/profile/models/order_history_model.dart';

class LabPartnerReviewBottomSheet extends StatefulWidget {
  final OrderHistoryItem order;

  const LabPartnerReviewBottomSheet({super.key, required this.order});

  @override
  State<LabPartnerReviewBottomSheet> createState() => _LabPartnerReviewBottomSheetState();
}

class _LabPartnerReviewBottomSheetState extends State<LabPartnerReviewBottomSheet> {
  final ApiClient _apiClient = ApiClient();
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiClient.post(
        '/labs/orders/${widget.order.id}/submit-review/',
        body: {
          'rating': _rating,
          'review_text': _reviewController.text.trim(),
        },
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
                const Text('Rate Lab Partner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabHeader(),
            const SizedBox(height: 32),
            const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildStarRating(),
            const SizedBox(height: 32),
            const Text('Share more about your experience (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Tell us about the home collection service quality...',
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

  Widget _buildLabHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.biotech_outlined, color: FemFlowColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.order.details['lab_name'] ?? 'Diagnostic Lab', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.order.details['branch_name'] ?? 'Local Branch', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
}
