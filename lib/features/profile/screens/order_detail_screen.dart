import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import 'package:femlyra/features/lab_tests/widgets/lab_partner_review_bottom_sheet.dart';
import '../models/order_history_model.dart';

// Automatic Payment resumes
import 'package:femlyra/features/doctor_consultation/doctor_payment_screen.dart';
import 'package:femlyra/features/doctor_consultation/data/doctor_consultation_service.dart';
import 'package:femlyra/features/subscriptions/screens/payment_screen.dart';
import 'package:femlyra/features/subscriptions/data/subscription_service.dart';
import 'package:femlyra/features/lab_tests/lab_payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderHistoryItem order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderHistoryItem _order;
  bool _hasUpdated = false;
  bool _isResumingPayment = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _handlePaymentResumption() async {
    setState(() {
      _isResumingPayment = true;
    });

    try {
      if (_order.type == 'Consultation') {
        final booking = await DoctorConsultationService().getBookingDetail(_order.id);
        final doctor = await DoctorConsultationService().getDoctorDetail(booking.doctorId);
        final date = DateTime.tryParse(booking.appointmentDate) ?? DateTime.now();

        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorPaymentScreen(
              doctor: doctor,
              date: date,
              time: booking.appointmentTime,
              mode: booking.consultationMode,
              bookingId: booking.id,
              paymentOrder: {
                'payment_order_number': booking.bookingIdDisplay,
                'amount': booking.consultationFee,
              },
            ),
          ),
        );
        if (result == true || result == null) {
          setState(() {
            _hasUpdated = true;
          });
        }
      } else if (_order.type == 'Subscription') {
        final plans = await SubscriptionService().getPlans();
        final planName = _order.details['plan_name'] ?? _order.displayName;
        final planKey = _order.details['plan_key'] ?? '';
        final plan = plans.firstWhere(
          (p) => p.planKey == planKey || p.name.toLowerCase() == planName.toLowerCase(),
          orElse: () => plans.first,
        );

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(plan: plan),
          ),
        );
        setState(() {
          _hasUpdated = true;
        });
      } else if (_order.type == 'LabTest') {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LabPaymentScreen(
              orderId: _order.id,
              orderNumber: _order.orderId,
              packageName: _order.displayName,
              amount: _order.amount,
            ),
          ),
        );
        setState(() {
          _hasUpdated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resume payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResumingPayment = false;
        });
      }
    }
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

    IconData iconData;
    Color iconColor;
    if (isSubscription) {
      iconData = Icons.workspace_premium;
      iconColor = Colors.pink;
    } else if (_order.type == 'LabTest') {
      iconData = Icons.biotech_outlined;
      iconColor = Colors.teal;
    } else {
      iconData = Icons.video_call;
      iconColor = Colors.purple;
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasUpdated) {
          // Pass back update flag
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: FemLyraColors.warmWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
            onPressed: () => Navigator.pop(context, _hasUpdated),
          ),
          title: const Text(
            'Order Details',
            style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
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
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: iconColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _order.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order Reference: ${_order.orderId}',
                      style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary, fontFamily: 'monospace'),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary, letterSpacing: 1.1),
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
                    ] else if (_order.type == 'LabTest') ...[
                      _buildDetailRow('Lab Partner', _order.details['lab_name'] ?? 'N/A'),
                      _buildDetailRow('Branch Branch', _order.details['branch_name'] ?? 'N/A'),
                      _buildDetailRow('Test Date', _order.details['booking_date'] ?? 'N/A'),
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
                'PAYMENT INFORMATION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),

              if (isPending) ...[
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, color: FemLyraColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Secure Payment Gateway',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This payment is automatically processed. Press the button below to pay securely via Razorpay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FemLyraColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isResumingPayment ? null : _handlePaymentResumption,
                          icon: _isResumingPayment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.payment),
                          label: const Text('Pay Securely', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (_order.utrNumber != null || _order.details['razorpay_payment_id'] != null)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Payment ID',
                          _order.details['razorpay_payment_id'] ?? _order.utrNumber!,
                          isMono: true,
                        ),
                        if (_order.details['razorpay_order_id'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Gateway Order ID', _order.details['razorpay_order_id']!, isMono: true),
                        ],
                      ],
                    ),
                  ),

                if (_order.type == 'LabTest') ...[
                  if (_order.details['report_url'] != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(_order.details['report_url']);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download Lab Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                  if (_order.status.toLowerCase() == 'success' && _order.details['has_review'] != true) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: FemLyraColors.primary),
                          foregroundColor: FemLyraColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final result = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => LabPartnerReviewBottomSheet(order: _order),
                          );
                          if (result == true) {
                            setState(() {
                              _hasUpdated = true;
                              _order.details['has_review'] = true;
                            });
                          }
                        },
                        icon: const Icon(Icons.star_outline_rounded),
                        label: const Text('Rate Lab Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ],
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
            style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: FemLyraColors.textPrimary,
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
