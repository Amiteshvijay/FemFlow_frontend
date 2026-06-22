import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/order_history_model.dart';
import 'payment_verification_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderHistoryItem order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderHistoryItem _order;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
      case 'booked':
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'pending_payment':
      case 'paymentpending':
      case 'created':
        return Colors.amber[800]!;
      case 'verification_pending':
      case 'verificationpending':
        return Colors.purple;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        return 'Paid / Success';
      case 'pending':
      case 'pending_payment':
      case 'paymentpending':
        return 'Pending Payment';
      case 'verification_pending':
      case 'verificationpending':
        return 'Verification Pending';
      case 'failed':
        return 'Failed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubscription = _order.type == 'Subscription';
    final formattedDate = DateFormat('MMMM dd, yyyy  hh:mm a').format(_order.createdAt);
    final isPending = ['pending', 'pending_payment', 'paymentpending'].contains(_order.status.toLowerCase());

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasUpdated) {
          // Pass back update flag
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: FemFlowColors.warmWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
            onPressed: () => Navigator.pop(context, _hasUpdated),
          ),
          title: const Text(
            'Order Details',
            style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (isSubscription ? Colors.pink : Colors.purple).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSubscription ? Icons.workspace_premium : Icons.video_call,
                        color: isSubscription ? Colors.pink : Colors.purple,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _order.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order Reference: ${_order.orderId}',
                      style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 16),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(_order.status).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _formatStatus(_order.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_order.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 40),

              // Specifications
              const Text(
                'ORDER SPECIFICATIONS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow('Order Type', _order.type),
                    _buildDetailRow('Amount Charged', '${_order.currency == 'INR' ? '₹' : _order.currency}${_order.amount.toInt()}'),
                    _buildDetailRow('Date Created', formattedDate),
                    if (isSubscription) ...[
                      _buildDetailRow('Plan Package', _order.details['plan_name'] ?? 'Premium'),
                    ] else ...[
                      _buildDetailRow('Doctor Name', 'Dr. ${_order.details['doctor_name'] ?? 'Consultant'}'),
                      _buildDetailRow('Appointment Date', _order.details['appointment_date'] ?? 'N/A'),
                      _buildDetailRow('Appointment Time', _order.details['appointment_time'] ?? 'N/A'),
                      _buildDetailRow('Consultation Mode', (_order.details['consultation_mode'] ?? 'Video').toUpperCase()),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment Info
              const Text(
                'PAYMENT & VERIFICATION INFORMATION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),

              if (isPending) ...[
                // Scan and Pay details
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_outlined, color: FemFlowColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('UPI Scan & Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_order.qrCodeUrl != null)
                        Center(
                          child: Container(
                            height: 160,
                            width: 160,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.network(_order.qrCodeUrl!, fit: BoxFit.contain),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (_order.upiLink != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FemFlowColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(_order.upiLink!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Launch UPI Apps', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text('UPI ID: femflow@upi', style: TextStyle(color: FemFlowColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button to upload verification
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentVerificationScreen(order: _order),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          _hasUpdated = true;
                          // Mimic verification submission status update
                          _order = OrderHistoryItem(
                            id: _order.id,
                            uuid: _order.uuid,
                            orderId: _order.orderId,
                            type: _order.type,
                            displayName: _order.displayName,
                            amount: _order.amount,
                            currency: _order.currency,
                            status: 'verification_pending',
                            createdAt: _order.createdAt,
                            details: _order.details,
                            upiLink: _order.upiLink,
                            qrCodeUrl: _order.qrCodeUrl,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Submit UTR & Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ] else ...[
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_order.utrNumber != null)
                        _buildDetailRow('UTR Reference', _order.utrNumber!, isMono: true)
                      else
                        _buildDetailRow('UTR Reference', 'Not submitted'),
                      const SizedBox(height: 8),
                      if (_order.paymentScreenshot != null) ...[
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Screenshot', style: TextStyle(color: FemFlowColors.textSecondary)),
                            Text('Uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(_order.paymentScreenshot!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _order.paymentScreenshot!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Text('Click to view full image'));
                                },
                              ),
                            ),
                          ),
                        ),
                      ] else
                        _buildDetailRow('Screenshot File', 'No file uploaded'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: FemFlowColors.textPrimary,
                fontSize: 13,
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
