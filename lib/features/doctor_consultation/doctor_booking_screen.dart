import 'package:flutter/material.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:provider/provider.dart';
import 'package:femflow/features/auth/providers/auth_provider.dart';
import '../../core/security/app_lock_service.dart';
import 'package:femflow/shared/widgets/app_card.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'data/doctor_consultation_service.dart';
import 'models/doctor_models.dart';
import 'doctor_payment_success_screen.dart';

class DoctorBookingScreen extends StatefulWidget {
  final DoctorProfile doctor;

  const DoctorBookingScreen({super.key, required this.doctor});

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  late Razorpay _razorpay;

  String? _selectedMode;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  int _freeBookingsCount = 0;
  DateTime? _latestFreeBookingDate;
  bool _isLoadingBookingHistory = true;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.doctor.consultationModes.isNotEmpty ? widget.doctor.consultationModes.first : null;
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    try {
      final bookings = await _service.getMyBookings();
      final freeBookings = bookings.where((b) {
        final statusLower = b.status.toLowerCase();
        final paymentLower = b.paymentStatus.toLowerCase();
        return statusLower == 'community care' || 
               paymentLower == 'community care' || 
               paymentLower == 'free';
      }).toList();

      DateTime? latestDate;
      if (freeBookings.isNotEmpty) {
        freeBookings.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
        latestDate = DateTime.tryParse(freeBookings.first.appointmentDate);
      }

      setState(() {
        _freeBookingsCount = freeBookings.length;
        _latestFreeBookingDate = latestDate;
        _isLoadingBookingHistory = false;
      });
    } catch (e) {
      debugPrint('Error fetching booking history: $e');
      setState(() {
        _isLoadingBookingHistory = false;
      });
    }
  }

  bool get _isDiscountEligible {
    if (_isLoadingBookingHistory) return false;
    final profile = context.read<AuthProvider>().profile;
    final isEnrolled = profile?.isCommunityCareEnrolled ?? false;
    if (!isEnrolled) return false;
    if (_freeBookingsCount >= 2) return false;
    if (_freeBookingsCount == 1) {
      final checkDate = _selectedDate ?? DateTime.now();
      if (_latestFreeBookingDate != null) {
        final diff = checkDate.difference(_latestFreeBookingDate!).inDays.abs();
        if (diff < 30) return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _razorpay.clear();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
    });
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final slots = await _service.getAvailableSlots(widget.doctor.id, dateStr);
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load slots: $e')),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isBooking = true;
    });
    try {
      final bookingId = _currentBookingId;
      if (bookingId == null) return;

      final verification = await _service.verifyPayment(
        bookingId: bookingId,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (verification['booking_status'] == 'confirmed') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPaymentSuccessScreen(
              doctor: widget.doctor,
              date: _selectedDate!,
              time: _selectedTime!,
              mode: _selectedMode!,
              bookingId: bookingId,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed. Please contact support.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      context.read<AppLockService>().setTrustedExternalFlowActive(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')),
      );
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      context.read<AppLockService>().setTrustedExternalFlowActive(false);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
    setState(() {
      _isBooking = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  int? _currentBookingId;

  Future<void> _startBooking() async {
    if (_selectedMode == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select mode, date, and time.')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      
      final useCommunityCare = _isDiscountEligible;

      final bookingResponse = await _service.createBooking(
        doctorId: widget.doctor.id,
        consultationMode: _selectedMode!,
        appointmentDate: dateStr,
        appointmentTime: _selectedTime!,
        userNotes: _notesController.text,
        isCommunityCare: useCommunityCare,
      );

      _currentBookingId = bookingResponse['booking_id'];

      if (useCommunityCare) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPaymentSuccessScreen(
              doctor: widget.doctor,
              date: _selectedDate!,
              time: _selectedTime!,
              mode: _selectedMode!,
              bookingId: _currentBookingId!,
            ),
          ),
        );
        return;
      }

      final orderResponse = await _service.createPaymentOrder(_currentBookingId!);

      final options = {
        'key': orderResponse['key_id'],
        'amount': orderResponse['amount'],
        'currency': orderResponse['currency'],
        'name': 'FemFlow',
        'description': 'Doctor Consultation with ${widget.doctor.fullName}',
        'order_id': orderResponse['razorpay_order_id'],
        'prefill': {
          'contact': '',
          'email': 'user@example.com'
        },
        'theme': {
          'color': '#E85D8B'
        }
      };

      if (!mounted) return;
      context.read<AppLockService>().setTrustedExternalFlowActive(true);
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      context.read<AppLockService>().setTrustedExternalFlowActive(false);
      setState(() {
        _isBooking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnrolled = context.watch<AuthProvider>().profile?.isCommunityCareEnrolled ?? false;
    final hasDiscount = _isDiscountEligible;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Consultation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Summary
            AppCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(widget.doctor.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${widget.doctor.speciality} • ₹${widget.doctor.consultationFee.toInt()}'),
              ),
            ),
            const SizedBox(height: 24),

            // Mode Selector
            const Text('Select Consultation Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: widget.doctor.consultationModes.map((mode) {
                final isSelected = _selectedMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(mode.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMode = mode;
                      });
                    },
                    selectedColor: FemFlowColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? FemFlowColors.primary : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedMode?.toLowerCase() == 'offline') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withValues(alpha: 0.05),
                  border: Border.all(color: FemFlowColors.primary.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: FemFlowColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clinic Address for Offline Consultation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.doctor.clinicAddress ?? 'Not specified',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Date Picker
            const Text('Select Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _fetchSlots(date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Choose Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black87),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Slots
            const Text('Select Time Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _selectedDate == null
                    ? const Text('Please select a date first.', style: TextStyle(color: Colors.grey))
                    : _availableSlots.isEmpty
                        ? const Text('No slots available for this date.', style: TextStyle(color: Colors.grey))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: _availableSlots.length,
                            itemBuilder: (context, index) {
                                final slot = _availableSlots[index];
                                final isAvailable = slot['available'] == true; // Ensure boolean
                                final slotTime = slot['time'] ?? slot['patient_time'] ?? 'N/A';
                                final isSelected = _selectedTime == slotTime;
                                
                                return InkWell(
                                  onTap: isAvailable
                                      ? () {
                                          setState(() {
                                            _selectedTime = slotTime;
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? FemFlowColors.primary.withValues(alpha: 0.2)
                                          : isAvailable
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                      border: Border.all(
                                        color: isSelected
                                            ? FemFlowColors.primary
                                            : isAvailable
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade200,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      slotTime,
                                      style: TextStyle(
                                        color: isAvailable ? Colors.black87 : Colors.grey.shade400,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            const SizedBox(height: 24),

            // User Notes
            const Text('Describe your concern briefly', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share details to help the doctor understand...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            if (isEnrolled && !hasDiscount && !_isLoadingBookingHistory) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _freeBookingsCount >= 2
                            ? 'You have reached your limit of 2 free consultations under the Care Community Program. Standard fees apply.'
                            : 'A 30-day cooldown is required between your 1st and 2nd free consultations. '
                              'Next free booking available after ${_latestFreeBookingDate!.add(const Duration(days: 30)).day}/${_latestFreeBookingDate!.add(const Duration(days: 30)).month}/${_latestFreeBookingDate!.add(const Duration(days: 30)).year}.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Fee Summary
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (hasDiscount) ...[
                      _buildSummaryRow(
                        'Normal Consultation Fee', 
                        '₹${widget.doctor.consultationFee.toInt()}'
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Community Care Discount', style: TextStyle(color: Colors.grey)),
                          Text('-100%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total (Care Community Program)', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '₹0', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildSummaryRow(
                        'Net Consultation Fee', 
                        '₹${(widget.doctor.consultationFee / 1.18).toStringAsFixed(2)}'
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'CGST (9%)', 
                        '₹${((widget.doctor.consultationFee - (widget.doctor.consultationFee / 1.18)) / 2).toStringAsFixed(2)}'
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'SGST (9%)', 
                        '₹${((widget.doctor.consultationFee - (widget.doctor.consultationFee / 1.18)) / 2).toStringAsFixed(2)}'
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Platform Fee', style: TextStyle(color: Colors.grey)),
                          Text('₹0', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total (Inclusive of GST)', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '₹${widget.doctor.consultationFee.toInt()}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _startBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemFlowColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        hasDiscount 
                            ? 'Book Free Consultation' 
                            : 'Pay & Book - ₹${widget.doctor.consultationFee.toInt()}', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
              ),
            ),
            if (!hasDiscount) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Your payment is securely processed by Razorpay.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
