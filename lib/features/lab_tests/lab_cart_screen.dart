import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/core/network/api_client.dart';
import 'package:femlyra/shared/widgets/app_card.dart';
import 'package:femlyra/shared/widgets/coupon_referral_section.dart';
import 'providers/cart_provider.dart';
import 'lab_payment_screen.dart';

class LabCartScreen extends StatefulWidget {
  const LabCartScreen({super.key});

  @override
  State<LabCartScreen> createState() => _LabCartScreenState();
}

class _LabCartScreenState extends State<LabCartScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isCheckingOut = false;
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LabCartProvider>().fetchCart();
    });
  }

  Future<void> _handleCheckout(LabCartProvider cart) async {
    if (cart.items.isEmpty) return;

    setState(() => _isCheckingOut = true);

    try {
      // Create a single concatenated package name for simple payment display
      final packageNames = cart.items.map((e) => e['name']).join(', ');
      
      final response = await _apiClient.post(
        '/labs/orders/create/',
        body: {
          'package_name': packageNames,
          'amount': cart.totalAmount,
          'coupon_code': _appliedCouponCode,
          'referral_code': _appliedCouponCode,
        },
      );

      if (mounted) {
        setState(() => _isCheckingOut = false);
        
        // Navigate to payment screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LabPaymentScreen(
              orderId: response['id'],
              orderNumber: response['order_number'],
              packageName: response['package_name'],
              amount: response['amount'].toDouble(),
              razorpayOrder: response['razorpay_order'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lab Booking Cart',
          style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<LabCartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ...cart.items.map((item) => _buildCartItemCard(item, cart)),
                    const SizedBox(height: 8),
                    CouponReferralSection(
                      serviceType: 'lab',
                      originalAmount: cart.totalAmount,
                      itemDetails: {
                        'package_name': cart.items.map((e) => e['name']).join(', '),
                        'items_count': cart.items.length,
                      },
                      appliedCode: _appliedCouponCode,
                      appliedDiscount: _couponDiscount,
                      onCouponApplied: (code, disc, msg) {
                        setState(() {
                          _appliedCouponCode = code;
                          _couponDiscount = disc;
                        });
                      },
                      onCouponRemoved: () {
                        setState(() {
                          _appliedCouponCode = null;
                          _couponDiscount = 0.0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildPriceSummary(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FemLyraColors.blushMist.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: FemLyraColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some packages to get started.',
            style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: FemLyraColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Browse Packages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item, LabCartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FemLyraColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reports in ${item['turnaround']}',
                    style: const TextStyle(fontSize: 11, color: FemLyraColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '₹${item['sellingPrice']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${item['mrp']}',
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: FemLyraColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              onPressed: () => cart.removeItem(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(LabCartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FemLyraColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 13)),
                Text('₹${cart.subtotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, color: FemLyraColors.textPrimary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Home Collection Charges', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 13)),
                Text('₹${cart.collectionFee.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, color: FemLyraColors.textPrimary, fontSize: 13)),
              ],
            ),
            if (_couponDiscount > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Coupon Discount (${_appliedCouponCode ?? ''})', style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('-₹${_couponDiscount.toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: FemLyraColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary, fontSize: 15)),
                Text('₹${((cart.totalAmount - _couponDiscount).clamp(0.0, double.infinity)).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isCheckingOut ? null : () => _handleCheckout(cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemLyraColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isCheckingOut
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Proceed to Book',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
