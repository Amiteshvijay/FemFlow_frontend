import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/core/network/api_client.dart';
import 'package:femlyra/core/config/brand_config.dart';
import 'package:femlyra/features/auth/providers/auth_provider.dart';
import 'package:femlyra/features/shell/main_shell.dart';
import 'providers/cart_provider.dart';

class LabPaymentScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String packageName;
  final double amount;
  final Map<String, dynamic>? razorpayOrder;

  const LabPaymentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.packageName,
    required this.amount,
    this.razorpayOrder,
  });

  @override
  State<LabPaymentScreen> createState() => _LabPaymentScreenState();
}

class _LabPaymentScreenState extends State<LabPaymentScreen> {
  final ApiClient _apiClient = ApiClient();
  late Razorpay _razorpay;
  bool _isProcessing = false;
  Map<String, dynamic>? _rzpOrderData;

  @override
  void initState() {
    super.initState();
    _rzpOrderData = widget.razorpayOrder;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Auto-launch if order data exists, else fetch it
    if (_rzpOrderData != null) {
      Future.microtask(() => _launchRazorpayCheckout());
    } else {
      Future.microtask(() => _fetchRazorpayOrder());
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchRazorpayOrder() async {
    setState(() => _isProcessing = true);
    try {
      final response = await _apiClient.post('/labs/orders/${widget.orderId}/initiate-payment/');
      if (mounted) {
        setState(() {
          _rzpOrderData = response;
          _isProcessing = false;
        });
        _launchRazorpayCheckout();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize payment: $e')),
        );
      }
    }
  }

  void _launchRazorpayCheckout() {
    if (_rzpOrderData == null) return;

    final authProvider = context.read<AuthProvider>();
    final userEmail = authProvider.profile?.email ?? '';
    final userContact = authProvider.profile?.mobileNumber ?? '';

    var options = {
      'key': _rzpOrderData!['key_id'],
      'amount': _rzpOrderData!['amount'], // in paise
      'name': BrandConfig.name,
      'description': 'Payment for ${widget.packageName}',
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
      debugPrint('Razorpay Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.post(
        '/labs/orders/${widget.orderId}/verify-payment/',
        body: {
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId ?? _rzpOrderData?['razorpay_order_id'],
          'razorpay_signature': response.signature,
        },
      );

      if (mounted) {
        context.read<LabCartProvider>().clear();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e. Please contact support.')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      String msg = response.code == 2 ? 'Payment cancelled' : (response.message ?? 'Payment failed');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _showSuccessDialog() {
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
            const Text('Booking Confirmed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your lab test booking has been confirmed successfully. Our partner laboratory will contact you for sample collection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
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
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Lab Test Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing)
              const CircularProgressIndicator(color: FemLyraColors.primary)
            else ...[
              const Icon(Icons.payment_outlined, size: 64, color: FemLyraColors.primary),
              const SizedBox(height: 24),
              Text(
                'Complete Payment for ${widget.packageName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Amount: ₹${widget.amount.toInt()}', style: const TextStyle(fontSize: 18, color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemLyraColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _launchRazorpayCheckout,
                  child: const Text('Retry Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
