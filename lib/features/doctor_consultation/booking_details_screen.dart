import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:FemLyra/core/theme/FemLyra_colors.dart';
import 'package:FemLyra/shared/widgets/app_card.dart';
import 'package:FemLyra/shared/widgets/primary_button.dart';
import 'data/doctor_consultation_service.dart';
import 'models/doctor_models.dart';
import 'invoice_screen.dart';
import '../profile/contact_us_screen.dart';
import 'widgets/doctor_review_bottom_sheet.dart';
import 'doctor_booking_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  DoctorBooking? _booking;
  bool _isLoading = true;

  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  bool get _canReschedule {
    if (_booking == null) return false;
    final status = _booking!.status.toLowerCase();
    if (status != 'confirmed' && status != 'upcoming' && status != 'booked') return false;
    
    try {
      final appointment = DateTime.parse('${_booking!.appointmentDate} ${_booking!.appointmentTime}');
      return appointment.isAfter(DateTime.now().add(const Duration(hours: 4)));
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleReschedule() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null || !mounted) return;
    
    _showSlotPicker(DateFormat('yyyy-MM-dd').format(pickedDate));
  }

  Future<void> _showSlotPicker(String date) async {
    setState(() => _isActionLoading = true);
    List<Map<String, dynamic>> slots = [];
    try {
      slots = await _service.getAvailableSlots(_booking!.doctorId, date);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching slots: $e')));
    } finally {
      setState(() => _isActionLoading = false);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Slots for $date', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (slots.isEmpty)
                const Center(child: Text('No slots available for this date.'))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.where((s) => s['available'] == true).map((slot) {
                    return ChoiceChip(
                      label: Text(slot['time']),
                      selected: false,
                      onSelected: (_) {
                        Navigator.pop(context);
                        _confirmReschedule(date, slot['time']);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReschedule(String date, String time) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reschedule'),
        content: Text('Are you sure you want to move your appointment to $date at $time?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reschedule')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionLoading = true);
      try {
        await _service.rescheduleBooking(
          bookingId: widget.bookingId,
          appointmentDate: date,
          appointmentTime: time,
        );
        await _fetchBookingDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment rescheduled successfully')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reschedule: $e')));
      } finally {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final booking = await _service.getBookingDetail(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 24),
                      _buildDoctorSection(),
                      const SizedBox(height: 24),
                      _buildAppointmentSection(),
                      const SizedBox(height: 24),
                      if (_booking!.status.toLowerCase() == 'completed') ...[
                        _buildPrescriptionSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildPaymentSection(),
                      _buildFollowUpsSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPrescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRESCRIPTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _booking!.hasPrescription
                ? Column(
                    children: [
                      _buildPrescriptionAction(
                        icon: Icons.visibility_outlined,
                        label: 'View Prescription',
                        onTap: () => _showPrescriptionPreview(),
                      ),
                      const Divider(height: 24),
                      _buildPrescriptionAction(
                        icon: Icons.download_outlined,
                        label: 'Download PDF',
                        onTap: () => _handlePrescriptionDownload(),
                      ),
                      if (_booking!.canFollowUp) ...[
                        const Divider(height: 24),
                        _buildPrescriptionAction(
                          icon: Icons.event_repeat,
                          label: 'Book Follow-up (₹${(_booking!.consultationFee * 0.5).toInt()}) - ${_booking!.followUpsCount + 1}/3',
                          onTap: () => _handleBookFollowUp(),
                        ),
                      ],
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 20, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Prescription will appear once shared by doctor.',
                          style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: FemLyraColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: FemLyraColors.primary),
        ],
      ),
    );
  }

  Future<void> _showPrescriptionPreview() async {
    setState(() => _isActionLoading = true);
    try {
      final prescription = await _service.getPrescription(widget.bookingId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Prescription Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diagnosis: ${prescription.diagnosis}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Medicines:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...prescription.medicines.map((m) {
                    if (m is Map) {
                      return Text('• ${m['name']} (${m['dosage']}) - ${m['frequency']}');
                    }
                    return Text('• $m');
                  }),
                  if (prescription.instructions != null && prescription.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(prescription.instructions!),
                  ],
                  if (prescription.precautions != null && prescription.precautions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Precautions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(prescription.precautions!),
                  ],
                  if (prescription.lifestyleRecommendations != null && prescription.lifestyleRecommendations!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Lifestyle Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(prescription.lifestyleRecommendations!),
                  ],
                  if (prescription.nextConsultationRecommendation != null && prescription.nextConsultationRecommendation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Next Consultation:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(prescription.nextConsultationRecommendation!),
                  ],
                  if (prescription.signatureStampUrl != null && prescription.signatureStampUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Authorized Signature / Stamp',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 60,
                            width: 120,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.network(
                              prescription.signatureStampUrl!,
                              fit: BoxFit.contain,
                              color: Colors.white,
                              colorBlendMode: BlendMode.multiply,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. ${prescription.doctorName}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load prescription: $e')));
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handlePrescriptionDownload() async {
    setState(() => _isActionLoading = true);
    try {
      await _service.downloadPrescriptionPdf(widget.bookingId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription downloaded successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleBookFollowUp() async {
    setState(() => _isActionLoading = true);
    try {
      final doctor = await _service.getDoctorDetail(_booking!.doctorId);
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorBookingScreen(
            doctor: doctor,
            originalBookingId: _booking!.id,
            followUpFee: _booking!.consultationFee * 0.5,
          ),
        ),
      ).then((_) {
        _fetchBookingDetails();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctor profile: $e')),
        );
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Widget _buildFollowUpsSection() {
    if (_booking!.followUps.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('FOLLOW-UP APPOINTMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        ..._booking!.followUps.map((followUp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: ListTile(
                title: Text('Follow-up Booking - ${followUp.bookingIdDisplay}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${followUp.appointmentDate} • Time: ${followUp.appointmentTime}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(followUp.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              followUp.status.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(followUp.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paid: ₹${followUp.consultationFee.toInt()}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: FemLyraColors.primary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsScreen(bookingId: followUp.id),
                    ),
                  ).then((_) => _fetchBookingDetails());
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return AppCard(
      color: _getStatusColor(_booking!.status).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: _getStatusColor(_booking!.status)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Status: ${_booking!.status.toUpperCase().replaceAll('_', ' ')}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(_booking!.status)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Booking ID: ${_booking!.bookingIdDisplay}', 
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DOCTOR DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: FemLyraColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: FemLyraColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_booking!.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_booking!.doctorSpecialty ?? 'Specialist', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('APPOINTMENT INFO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today, 'Date', _booking!.appointmentDate),
                const Divider(height: 24),
                _buildInfoRow(Icons.access_time, 'Time', _booking!.appointmentTime),
                const Divider(height: 24),
                _buildInfoRow(Icons.videocam, 'Consultation Type', _booking!.consultationMode.toUpperCase()),
                const Divider(height: 24),
                _buildInfoRow(Icons.timer, 'Duration', '30 Minutes'),
                if (_booking!.consultationMode.toLowerCase() == 'offline') ...[
                  const Divider(height: 24),
                  _buildInfoRow(Icons.location_on, 'Clinic Address', _booking!.clinicAddress ?? 'Not specified'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PAYMENT & INVOICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.currency_rupee, 'Amount Paid', '₹${_booking!.consultationFee.toInt()}'),
                const Divider(height: 24),
                _buildInfoRow(Icons.check_circle_outline, 'Payment Status', _booking!.paymentStatus.toUpperCase()),
                if (_booking!.razorpayPaymentId != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(Icons.receipt_long, 'Payment ID', _booking!.razorpayPaymentId!),
                ],
                if (_booking!.paymentStatus == 'paid') ...[
                  const Divider(height: 24),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(bookingId: _booking!.id))),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 18, color: FemLyraColors.primary),
                        const SizedBox(width: 12),
                        const Text('View Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: FemLyraColors.primary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if ((_booking!.status.toLowerCase() == 'confirmed' || _booking!.status.toLowerCase() == 'upcoming' || _booking!.status.toLowerCase() == 'booked') && _booking!.consultationMode.toLowerCase() != 'offline') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_booking!.meetLink != null && _booking!.meetLink!.isNotEmpty && _booking!.meetLink != "N/A") {
                  final url = Uri.parse(_booking!.meetLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open meeting link')),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meeting link is being prepared. Please check shortly.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FemLyraColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Join Consultation', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_booking!.status.toLowerCase() == 'completed' && !_booking!.hasReview) ...[
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Give Rating & Review',
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DoctorReviewBottomSheet(booking: _booking!),
                );
                if (result == true) {
                  _fetchBookingDetails();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_canReschedule) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isActionLoading ? null : _handleReschedule,
              style: OutlinedButton.styleFrom(
                foregroundColor: FemLyraColors.primary,
                side: const BorderSide(color: FemLyraColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isActionLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: FemLyraColors.primary))
                : const Text('Reschedule Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Get Support'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
      case 'booked':
        return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'pending_payment':
      case 'paymentpending':
      case 'verificationpending':
      case 'verification_pending':
        return Colors.orange;
      case 'in_progress': return Colors.purple;
      case 'review_submitted': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
