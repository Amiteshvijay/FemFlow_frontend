import 'package:femlyra/core/config/brand_config.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';
import '../data/subscription_service.dart';
import '../../shell/main_shell.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SubscriptionService _service = SubscriptionService();
  
  bool _isProcessing = false;
  String _statusMessage = 'Initializing secure payment...';
  bool _showRetryButton = false;
  Map<String, dynamic>? _orderData;

  Timer? _countdownTimer;
  int _secondsRemaining = 180; // 3 minutes

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    
    // Initialize Razorpay client
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

    // Auto-initiate order creation
    Future.microtask(() => _startPayment());
  }

  @override
  void dispose() {
    _razorpay.clear();
    _countdownTimer?.cancel();
    super.dispose();
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
    if (_orderData != null) {
      final orderId = _orderData!['order_id'];
      await _service.updatePaymentStage(orderId, 'abandoned');
    }
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

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying payment status...';
    });
    
    try {
      final verifyData = {
        'razorpay_order_id': response.orderId ?? _orderData?['order_id'],
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      };
      
      final provider = context.read<SubscriptionProvider>();
      await provider.verifyPayment(verifyData);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showRazorpaySuccessDialog();
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
      final orderId = _orderData?['order_id'] ?? 'FF-SUB';
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

  void _showRazorpaySuccessDialog() {
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
              'Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment of ₹${_orderData?['amount'] ?? widget.plan.price} has been successfully verified. '
              'Your premium features are now active!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemLyraColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final provider = context.read<SubscriptionProvider>();
                  await provider.loadStatus();
                  
                  if (!context.mounted) return;
 
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

  void _launchRazorpayCheckout() {
    if (_orderData == null) return;
    
    final authProvider = context.read<AuthProvider>();
    final userEmail = authProvider.profile?.email ?? '';
    final userContact = authProvider.profile?.mobileNumber ?? '';

    var options = {
      'key': _orderData!['key_id'],
      'amount': (_orderData!['amount'] * 100).toInt(),
      'name': 'FemLyra Premium',
      'description': 'Subscription to ${widget.plan.name}',
      'order_id': _orderData!['order_id'],
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

  Future<void> _startPayment() async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating secure order...';
      _showRetryButton = false;
      _orderData = null;
    });

    try {
      final orderData = await _service.createOrder(
        planId: widget.plan.id,
        planKey: widget.plan.planKey,
      );
      debugPrint('DEBUG: Order created successfully: $orderData');
      
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _orderData = orderData;
      });

      // Report initiated & checkout_viewed
      _service.updatePaymentStage(orderData['order_id'], 'initiated');
      _service.updatePaymentStage(orderData['order_id'], 'checkout_viewed');
      _startCountdown();
      
      // Auto-launch Razorpay checkout
      _launchRazorpayCheckout();
    } catch (e, stack) {
      debugPrint('DEBUG: UPI Order Creation Error: $e');
      debugPrint('DEBUG: Stack Trace: $stack');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showRetryButton = true;
          _statusMessage = 'Failed to create payment order.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize payment: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing || _orderData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: FemLyraColors.primary),
                const SizedBox(height: 32),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: FemLyraColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please do not close the app or press back.',
                  style: TextStyle(fontSize: 13, color: FemLyraColors.textMuted),
                ),
                if (_showRetryButton) ...[
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _startPayment,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: FemLyraColors.primary),
                        foregroundColor: FemLyraColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final amount = _orderData!['amount'];
    final orderId = _orderData!['order_id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Secure Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

              // Plan Summary Card
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
                      widget.plan.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Amount: ₹${amount.toString()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order Ref: $orderId',
                      style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
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
                    backgroundColor: FemLyraColors.primary,
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
    );
  }
}
