import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/FemLyra_colors.dart';

class CouponReferralSection extends StatefulWidget {
  final String serviceType; // 'doctor', 'lab', 'premium'
  final double originalAmount;
  final Map<String, dynamic>? itemDetails;
  final String? appliedCode;
  final double appliedDiscount;
  final Function(String code, double discountAmount, String message)? onCouponApplied;
  final VoidCallback? onCouponRemoved;

  const CouponReferralSection({
    super.key,
    required this.serviceType,
    required this.originalAmount,
    this.itemDetails,
    this.appliedCode,
    this.appliedDiscount = 0.0,
    this.onCouponApplied,
    this.onCouponRemoved,
  });

  @override
  State<CouponReferralSection> createState() => _CouponReferralSectionState();
}

class _CouponReferralSectionState extends State<CouponReferralSection> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _codeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndApply() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a referral or coupon code';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _apiClient.post('/referrals/validate/', body: {
        'referral_code': code,
        'service_type': widget.serviceType,
        'original_amount': widget.originalAmount,
        'item_details': widget.itemDetails ?? {},
      });

      if (response != null && response['valid'] == true) {
        final discountAmount = (response['discount_amount'] as num?)?.toDouble() ?? 0.0;
        final msg = response['message'] as String? ?? 'Code applied successfully!';

        setState(() {
          _isLoading = false;
          _successMessage = msg;
          _errorMessage = null;
        });

        if (widget.onCouponApplied != null) {
          widget.onCouponApplied!(code, discountAmount, msg);
        }
      } else {
        final msg = response?['message'] ?? 'Invalid referral or coupon code.';
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to validate code. Please try again.';
      });
    }
  }

  void _removeCoupon() {
    _codeController.clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    if (widget.onCouponRemoved != null) {
      widget.onCouponRemoved!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isApplied = widget.appliedCode != null && widget.appliedCode!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApplied ? Colors.green.shade50 : FemLyraColors.blushMist.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApplied ? Colors.green.shade300 : FemLyraColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApplied ? Icons.check_circle_outline : Icons.confirmation_number_outlined,
                size: 20,
                color: isApplied ? Colors.green.shade700 : FemLyraColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isApplied ? 'Coupon / Referral Applied' : 'Have a Coupon or Referral Code?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isApplied ? Colors.green.shade900 : FemLyraColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (isApplied) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appliedCode!,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.0,
                        color: Colors.green.shade900,
                      ),
                    ),
                    if (widget.appliedDiscount > 0)
                      Text(
                        'You saved ₹${widget.appliedDiscount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _removeCoupon,
                  icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter code (e.g. FEMWELCOME)',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: FemLyraColors.textMuted,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FemLyraColors.primary),
                        ),
                      ),
                      onSubmitted: (_) => _validateAndApply(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FemLyraColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _successMessage!,
                style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
