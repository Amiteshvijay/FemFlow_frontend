import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_io/io.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:femflow/core/security/app_lock_service.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:femflow/features/doctor_consultation/models/doctor_models.dart';
import 'package:femflow/features/doctor_consultation/data/doctor_consultation_service.dart';
import 'package:femflow/features/shell/main_shell.dart';
import 'package:femflow/core/services/deep_link_service.dart';
import 'package:femflow/features/auth/providers/auth_provider.dart';
import 'doctor_payment_success_screen.dart';

class DoctorPaymentScreen extends StatefulWidget {
  final DoctorProfile doctor;
  final DateTime date;
  final String time;
  final String mode;
  final int bookingId;
  final Map<String, dynamic> paymentOrder;

  const DoctorPaymentScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.mode,
    required this.bookingId,
    required this.paymentOrder,
  });

  @override
  State<DoctorPaymentScreen> createState() => _DoctorPaymentScreenState();
}

class _DoctorPaymentScreenState extends State<DoctorPaymentScreen> with WidgetsBindingObserver {
  final DoctorConsultationService _service = DoctorConsultationService();
  final TextEditingController _utrController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedScreenshot;
  bool _showQrCode = false;
  bool _showManualFallback = false;
  bool _isProcessing = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes

  // UPI Response and Fallback tracking fields
  bool _isWaitingForUpiResponse = false;
  Timer? _upiTimeoutTimer;
  int _upiSecondsRemaining = 60; // 1 minute
  StreamSubscription<Uri>? _linkSubscription;

  late Razorpay _razorpay;
  Map<String, dynamic>? _rzpOrderData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize Razorpay client
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

    final orderId = widget.paymentOrder['payment_order_number'] ?? widget.paymentOrder['transaction_note'] ?? 'FF-PAY';
    _service.updatePaymentStage(orderId, 'initiated');
    _service.updatePaymentStage(orderId, 'checkout_viewed');
    _startCountdown();

    // Auto-initiate Razorpay order creation
    Future.microtask(() => _initiateRazorpayOrder());

    // Listen to incoming deep links for payment callback
    _linkSubscription = DeepLinkService().uriStream.listen((uri) {
      if (uri.scheme == 'femflow' && uri.host == 'upi-callback') {
        _handleUpiIntentCallback(uri);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _razorpay.clear();
    _linkSubscription?.cancel();
    _countdownTimer?.cancel();
    _upiTimeoutTimer?.cancel();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _initiateRazorpayOrder() async {
    setState(() {
      _isProcessing = true;
    });
    try {
      final rzpOrderData = await _service.createRazorpayOrder(widget.bookingId);
      if (mounted) {
        setState(() {
          _rzpOrderData = rzpOrderData;
          _isProcessing = false;
        });
        // Auto-launch checkout dialog
        _launchRazorpayCheckout();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        debugPrint('Failed to initialize Razorpay order: $e');
      }
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final verifyData = {
        'razorpay_order_id': response.orderId ?? _rzpOrderData?['razorpay_order_id'],
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      };
      
      await _service.verifyRazorpayPayment(widget.bookingId, verifyData);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPaymentSuccessScreen(
              doctor: widget.doctor,
              date: widget.date,
              time: widget.time,
              mode: widget.mode,
              bookingId: widget.bookingId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment verification failed: $e. Please contact support.')),
        );
      }
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    debugPrint('Razorpay Payment Error: ${response.code} | ${response.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment cancelled or failed: ${response.message}')),
      );
    }
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
  }

  void _launchRazorpayCheckout() {
    if (_rzpOrderData == null) return;
    
    final authProvider = context.read<AuthProvider>();
    final userEmail = authProvider.profile?.email ?? '';
    final userContact = authProvider.profile?.mobileNumber ?? '';

    var options = {
      'key': _rzpOrderData!['key_id'],
      'amount': _rzpOrderData!['amount'], // already in paise
      'name': 'FemFlow Doctor Consultation',
      'description': 'Consultation with Dr. ${widget.doctor.fullName}',
      'order_id': _rzpOrderData!['razorpay_order_id'],
      'image': 'https://femflow.in/logo.png',
      'prefill': {
        'contact': userContact,
        'email': userEmail,
      },
      'theme': {
        'color': '#E85D8B'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Checkout Launch Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Razorpay checkout: $e')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForUpiResponse) {
      _showLifecycleResumePrompt();
    }
  }

  void _startUpiTimeoutTimer() {
    _upiTimeoutTimer?.cancel();
    _upiSecondsRemaining = 60;
    _upiTimeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_upiSecondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _upiSecondsRemaining--;
          });
        }
      } else {
        _upiTimeoutTimer?.cancel();
        _handleUpiTimeout();
      }
    });
  }

  void _handleUpiTimeout() {
    if (!mounted) return;
    setState(() {
      _isWaitingForUpiResponse = false;
      _showManualFallback = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI response timed out. Please enter UTR below to verify.'),
        duration: Duration(seconds: 6),
      ),
    );
  }

  void _handleUpiIntentCallback(Uri uri) {
    if (!_isWaitingForUpiResponse) return;
    _upiTimeoutTimer?.cancel();
    
    final status = (uri.queryParameters['status'] ?? uri.queryParameters['Status'] ?? '').toLowerCase();
    
    if (status == 'success') {
      _verifyTransactionImmediately();
    } else if (status == 'failure' || status == 'failed' || status == 'cancelled') {
      setState(() {
        _isWaitingForUpiResponse = false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment was cancelled or failed. Please try again.')),
      );
    }
  }

  Future<void> _verifyTransactionImmediately() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      
      final booking = await _service.getBookingDetail(widget.bookingId);
      if (!mounted) return;
      
      if (booking.paymentStatus == 'paid' || booking.status == 'confirmed' || booking.status == 'verification_pending') {
        _showSuccessDialog('UPI Automatic Verification');
      } else {
        setState(() {
          _isWaitingForUpiResponse = false;
          _isProcessing = false;
          _showManualFallback = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification is pending bank clearance. Please enter UTR below to speed up.'),
            duration: Duration(seconds: 7),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isWaitingForUpiResponse = false;
        _isProcessing = false;
        _showManualFallback = true;
      });
    }
  }

  void _showLifecycleResumePrompt() {
    if (!mounted) return;
    _upiTimeoutTimer?.cancel();
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline_rounded, color: FemFlowColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Confirm Payment Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Did you complete the payment in your UPI app?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isWaitingForUpiResponse = false;
                          _isProcessing = false;
                          _showManualFallback = false;
                        });
                      },
                      child: const Text('Cancel / Retry', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FemFlowColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _verifyTransactionImmediately();
                      },
                      child: const Text('Yes, I Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = 300;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _countdownTimer?.cancel();
        _handlePaymentTimeout();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handlePaymentTimeout() async {
    final orderId = widget.paymentOrder['payment_order_number'] ?? widget.paymentOrder['transaction_note'] ?? 'FF-PAY';
    await _service.updatePaymentStage(orderId, 'abandoned');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment session has expired. Please try again.'),
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickScreenshot() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedScreenshot = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Failed to pick screenshot: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitUtr(String utrNumber) async {
    if (_selectedScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment screenshot is mandatory. Please upload first.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      await _service.submitUtr(widget.bookingId, utrNumber, _selectedScreenshot);
      
      final orderId = widget.paymentOrder['payment_order_number'] ?? widget.paymentOrder['transaction_note'] ?? 'FF-PAY';
      await _service.updatePaymentStage(orderId, 'utr_submitted');

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSuccessDialog(utrNumber);
      }
    } catch (e) {
      debugPrint('DEBUG: UTR Submission Error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit UTR: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(String utrNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Booking Requested',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment of ₹${widget.paymentOrder['amount'] ?? widget.doctor.consultationFee} with UTR $utrNumber has been submitted for verification. '
              'Your booking status is now "Verification Pending" and will be confirmed shortly after support verification.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemFlowColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.paymentOrder['amount'] ?? widget.doctor.consultationFee;
    final upiLink = widget.paymentOrder['upi_link'];
    final qrCodeUrl = widget.paymentOrder['qr_code_url'];
    final paymentOrderNumber = widget.paymentOrder['payment_order_number'] ?? widget.paymentOrder['transaction_note'] ?? 'FF-PAY';
    final dateStr = DateFormat('MMMM dd, yyyy').format(widget.date);

    if (_isProcessing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: FemFlowColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Submitting payment reference...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Consultation Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Countdown Timer Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payment session expires in: ${_formatTime(_secondsRemaining)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Booking Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FemFlowColors.blushMist.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FemFlowColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctor.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.doctor.speciality} • ${widget.mode.toUpperCase()}',
                        style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${widget.time}',
                        style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Amount: ₹${amount.toString()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order Reference: $paymentOrderNumber',
                        style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Razorpay Checkout launch button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FemFlowColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _launchRazorpayCheckout();
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Pay Securely (Cards, UPI, Netbanking)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
