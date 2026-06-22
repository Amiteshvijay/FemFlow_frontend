import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../core/security/app_lock_service.dart';
import 'package:provider/provider.dart';
import '../data/profile_service.dart';
import '../models/order_history_model.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final OrderHistoryItem order;

  const PaymentVerificationScreen({super.key, required this.order});

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _utrController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _screenshotFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final appLock = context.read<AppLockService>();
    try {
      appLock.setTrustedExternalFlowActive(true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _screenshotFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      appLock.setTrustedExternalFlowActive(false);
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final utr = _utrController.text.trim();
      
      if (widget.order.type == 'Subscription') {
        await _profileService.submitSubscriptionUtr(
          orderId: widget.order.orderId,
          utrNumber: utr,
          screenshotFile: _screenshotFile,
        );
      } else {
        // Consultation
        await _profileService.submitConsultationUtr(
          bookingId: widget.order.id,
          utrNumber: utr,
          screenshotFile: _screenshotFile,
        );
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Submitted successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your UTR details have been uploaded. The admin verification team is validating the transaction. Updates will reflect shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemFlowColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Pop dialog
                  Navigator.pop(context, true); // Pop verification screen and pass true to trigger reload
                },
                child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Payment',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit payment transaction details below to verify your purchase.',
                style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),

              // UTR Number Input
              const Text(
                '12-DIGIT TRANSACTION UTR NUMBER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _utrController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'UTR Number',
                  hintText: 'Enter 12-digit transaction ID',
                  prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  helperText: 'Usually found in GPay/PhonePe payment details.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the transaction UTR number';
                  }
                  final trimmed = value.trim();
                  if (trimmed.length != 12 || !RegExp(r'^\d+$').hasMatch(trimmed)) {
                    return 'Please enter a valid 12-digit numeric UTR';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Screenshot Picker Card
              const Text(
                'TRANSACTION SCREENSHOT (OPTIONAL)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _screenshotFile != null
                      ? Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _screenshotFile!,
                                height: 160,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to change image',
                              style: TextStyle(color: FemFlowColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Column(
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: FemFlowColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'Select Screenshot from Gallery',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemFlowColors.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Accepts PNG, JPG, JPEG (Max 5MB)',
                              style: TextStyle(color: FemFlowColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemFlowColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitVerification,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Verification',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
