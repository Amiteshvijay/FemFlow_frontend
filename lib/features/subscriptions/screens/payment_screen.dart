import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_io/io.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/theme/femflow_colors.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';
import '../data/subscription_service.dart';
import '../../shell/main_shell.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  final SubscriptionService _service = SubscriptionService();
  final TextEditingController _utrController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedScreenshot;
  bool _showQrCode = false;
  bool _showManualFallback = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing secure payment...';
  bool _showRetryButton = false;
  Map<String, dynamic>? _orderData;

  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes

  // UPI Response and Fallback tracking fields
  bool _isWaitingForUpiResponse = false;
  Timer? _upiTimeoutTimer;
  int _upiSecondsRemaining = 60; // 1 minute
  StreamSubscription<Uri>? _linkSubscription;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize Razorpay client
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

    // Auto-initiate order creation
    Future.microtask(() => _startPayment());

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
      _statusMessage = 'Verifying payment with bank...';
    });

    try {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      
      final provider = context.read<SubscriptionProvider>();
      await provider.loadStatus();
      if (!mounted) return;
      
      if (provider.isPremium) {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment cancelled or failed: ${response.message}')),
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
                  backgroundColor: FemFlowColors.primary,
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
      'name': 'FemFlow Premium',
      'description': 'Subscription to ${widget.plan.name}',
      'order_id': _orderData!['order_id'],
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

  Future<void> _submitUtr(String orderId, String utrNumber) async {
    if (_selectedScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment screenshot is mandatory. Please upload first.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Submitting UTR for verification...';
    });

    try {
      final provider = context.read<SubscriptionProvider>();
      await provider.submitUtr(orderId, utrNumber, _selectedScreenshot);
      
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
          SnackBar(content: Text('Failed to submit UTR: $e'))
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
              'Verification Submitted',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment of ₹${_orderData?['amount'] ?? widget.plan.price} with UTR $utrNumber has been submitted for verification. '
              'Your premium features will activate shortly once verified by support.',
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
                  // Refresh global subscription status immediately
                  final provider = context.read<SubscriptionProvider>();
                  await provider.loadStatus();
                  
                  if (!context.mounted) return;

                  // Robust navigation back to Home
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
                      label: const Text('Retry'),
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

    final amount = _orderData!['amount'];
    final orderId = _orderData!['order_id'];
    final upiLink = _orderData!['upi_link'];
    final qrCodeUrl = _orderData!['qr_code_url'];

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

                // Plan Summary Card
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
                        widget.plan.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ₹${amount.toString()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order Ref: $orderId',
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
