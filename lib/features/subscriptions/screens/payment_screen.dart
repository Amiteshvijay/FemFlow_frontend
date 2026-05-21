import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/theme/femflow_colors.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';
import '../data/subscription_service.dart';
import '../../shell/main_shell.dart';

class PaymentScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  final SubscriptionService _service = SubscriptionService();
  bool _isProcessing = false;
  String _statusMessage = 'Initializing secure payment...';
  bool _showRetryButton = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Auto-initiate order
    Future.microtask(() => _startPayment());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPayment() async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating secure order...';
      _showRetryButton = false;
    });

    // Timeout to show retry button if it hangs
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isProcessing && !_showRetryButton) {
        setState(() => _showRetryButton = true);
      }
    });

    try {
      final orderData = await _service.createOrder(
        planId: widget.plan.id,
        planKey: widget.plan.planKey,
      );
      debugPrint('DEBUG: Order created successfully: $orderData');
      
      if (!mounted) return;
      setState(() => _statusMessage = 'Opening secure gateway...');

      var options = {
        'key': orderData['key_id'],
        'amount': orderData['amount'],
        'name': 'FemFlow Premium',
        'description': widget.plan.name,
        'order_id': orderData['order_id'],
        'timeout': 300,
        'external': {
          'wallets': ['paytm']
        }
      };

      // Add prefill only if we have data (optional)
      // options['prefill'] = {'contact': '', 'email': ''};

      debugPrint('DEBUG: Opening Razorpay with options: $options');
      context.read<AppLockService>().setTrustedExternalFlowActive(true);
      _razorpay.open(options);
      
      // We keep _isProcessing = true until we get a success or error event
      // This keeps the spinner visible until the Razorpay UI takes over
    } catch (e, stack) {
      debugPrint('DEBUG: Razorpay Init Error: $e');
      debugPrint('DEBUG: Stack Trace: $stack');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showRetryButton = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize: $e')));
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying payment status...';
      _showRetryButton = false; // Hide retry button during active verification
    });

    try {
      final verifyData = {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      };

      if (!mounted) return;
      
      await context.read<SubscriptionProvider>().verifyPayment(verifyData);
      
      if (mounted) {
        // SUCCESS: Explicitly stop processing and show dialog
        context.read<AppLockService>().setTrustedExternalFlowActive(false);
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Payment Verified!';
        });
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('DEBUG: Verification Error: $e');
      if (mounted) {
        context.read<AppLockService>().setTrustedExternalFlowActive(false);
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Verification failed. Please check your internet.';
          _showRetryButton = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment verification failed: $e'),
          action: SnackBarAction(label: 'Retry', onPressed: () => _handlePaymentSuccess(response)),
        ));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      context.read<AppLockService>().setTrustedExternalFlowActive(false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${response.message}')));
      Navigator.pop(context);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
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
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your ${widget.plan.name} is now active. Enjoy your premium wellness insights.',
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
                onPressed: () async {
                  // 1. Refresh global subscription status immediately
                  final provider = context.read<SubscriptionProvider>();
                  await provider.loadStatus();
                  
                  if (!context.mounted) return;

                  // 2. Robust navigation back to Home
                  // We clear everything and go back to index 0 of the shell
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
              const CircularProgressIndicator(color: FemFlowColors.primary),
              const SizedBox(height: 32),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: FemFlowColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please do not close the app or press back.',
                style: TextStyle(fontSize: 13, color: FemFlowColors.textMuted),
              ),
              if (_showRetryButton) ...[
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _startPayment,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Initialization'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: FemFlowColors.primary),
                      foregroundColor: FemFlowColors.primary,
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
}
