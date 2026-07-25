import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/features/doctor_consultation/models/doctor_models.dart';
import 'package:femlyra/features/doctor_consultation/data/doctor_consultation_service.dart';
import 'package:femlyra/features/auth/providers/auth_provider.dart';
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

class _DoctorPaymentScreenState extends State<DoctorPaymentScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  bool _isProcessing = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 180; // 3 minutes

  late Razorpay _razorpay;
  Map<String, dynamic>? _rzpOrderData;

  @override
  void initState() {
    super.initState();
    
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
  }

  @override
  void dispose() {
    _razorpay.clear();
    _countdownTimer?.cancel();
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
    
    // Update backend stage to failed or abandoned
    try {
      final orderId = widget.paymentOrder['payment_order_number'] ?? widget.paymentOrder['transaction_note'] ?? 'FF-PAY';
      final stage = response.code == 2 ? 'abandoned' : 'failed';
      _service.updatePaymentStage(orderId, stage);
    } catch (_) {}

    if (mounted) {
      String errorMsg = 'Payment failed. Please try again.';
      if (response.code == 2) {
        errorMsg = 'Payment was cancelled.';
      } else if (response.message != null && response.message!.isNotEmpty && response.message != 'undefined') {
        errorMsg = response.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
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
      'name': 'FemLyra Doctor Consultation',
      'description': 'Consultation with Dr. ${widget.doctor.fullName}',
      'order_id': _rzpOrderData!['razorpay_order_id'],
      'image': 'https://femlyra.com/logo.png',
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

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = 180;
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

  String get _amountDisplay {
    double consultationFee = widget.doctor.consultationFee;
    double platformFee = consultationFee * 0.005;
    double fallbackAmount = consultationFee + platformFee;
    
    double rawAmountDouble;
    final orderAmount = widget.paymentOrder['amount'];
    if (orderAmount != null) {
      if (orderAmount is num) {
        rawAmountDouble = orderAmount.toDouble();
      } else {
        rawAmountDouble = double.tryParse(orderAmount.toString()) ?? fallbackAmount;
      }
    } else {
      rawAmountDouble = fallbackAmount;
    }
    
    return rawAmountDouble % 1 == 0 ? rawAmountDouble.toInt().toString() : rawAmountDouble.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = _amountDisplay;
    final paymentOrderNumber = widget.paymentOrder['payment_order_number'] ?? widget.paymentOrder['transaction_note'] ?? 'FF-PAY';
    final dateStr = DateFormat('MMMM dd, yyyy').format(widget.date);

    if (_isProcessing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: FemLyraColors.primary),
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
                  color: FemLyraColors.blushMist.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FemLyraColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.doctor.speciality} • ${widget.mode.toUpperCase()}',
                      style: const TextStyle(fontSize: 13, color: FemLyraColors.textSecondary),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Date: $dateStr',
                      style: const TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${widget.time}',
                      style: const TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Amount: ₹$amountStr',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order Reference: $paymentOrderNumber',
                      style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Razorpay Checkout launch button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: FemLyraColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _launchRazorpayCheckout();
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [FemLyraColors.primary, FemLyraColors.deepRose],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Proceed to Pay  •  ₹$amountStr',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cards, UPI, Netbanking & Wallets',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
