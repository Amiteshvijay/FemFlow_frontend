import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/core/network/api_client.dart';
import 'package:femlyra/core/security/app_lock_service.dart';
import 'package:femlyra/shared/widgets/app_card.dart';
import 'package:femlyra/features/profile/screens/order_history_screen.dart';
import 'providers/cart_provider.dart';

class LabPaymentScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String packageName;
  final double amount;
  final String? upiLink;
  final String? qrCodeUrl;

  const LabPaymentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.packageName,
    required this.amount,
    this.upiLink,
    this.qrCodeUrl,
  });

  @override
  State<LabPaymentScreen> createState() => _LabPaymentScreenState();
}

class _LabPaymentScreenState extends State<LabPaymentScreen> {
  final ApiClient _apiClient = ApiClient();
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
      
      await _apiClient.multipartPost(
        '/labs/orders/${widget.orderId}/submit-utr/',
        fields: {
          'utr_number': utr,
        },
        fileFieldName: 'payment_screenshot',
        file: _screenshotFile,
      );

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
              style: TextStyle(fontSize: 13, color: FemLyraColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemLyraColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  context.read<LabCartProvider>().clear();
                  Navigator.pop(context); // Pop dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                  );
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
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
          onPressed: () {
            // Warn that navigating away won't cancel the order draft
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Booking Payment',
          style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
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
              Text(
                'Complete your booking for ${widget.packageName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ID: ${widget.orderNumber}',
                style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 24),

              // QR Code and UPI section
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Pay ₹${widget.amount.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FemLyraColors.primary),
                    ),
                    const SizedBox(height: 16),
                    if (widget.qrCodeUrl != null)
                      Center(
                        child: Container(
                          height: 180,
                          width: 180,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.network(widget.qrCodeUrl!, fit: BoxFit.contain),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (widget.upiLink != null)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FemLyraColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse(widget.upiLink!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          label: const Text('Pay via UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'UPI ID: FemLyra@ybl',
                      style: TextStyle(color: FemLyraColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // UTR verification
              const Text(
                '12-DIGIT TRANSACTION UTR NUMBER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary, letterSpacing: 1.1),
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

              // Screenshot upload
              const Text(
                'TRANSACTION SCREENSHOT (OPTIONAL)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                              style: TextStyle(color: FemLyraColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Column(
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: FemLyraColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'Select Screenshot from Gallery',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemLyraColors.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Accepts PNG, JPG, JPEG (Max 5MB)',
                              style: TextStyle(color: FemLyraColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 36),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemLyraColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
