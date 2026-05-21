import 'package:flutter/material.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:femflow/shared/widgets/app_card.dart';
import 'data/doctor_consultation_service.dart';
import 'models/doctor_models.dart';
import 'booking_details_screen.dart';

class MyDoctorBookingsScreen extends StatefulWidget {
  const MyDoctorBookingsScreen({super.key});

  @override
  State<MyDoctorBookingsScreen> createState() => _MyDoctorBookingsScreenState();
}

class _MyDoctorBookingsScreenState extends State<MyDoctorBookingsScreen> with SingleTickerProviderStateMixin {
  final DoctorConsultationService _service = DoctorConsultationService();
  late TabController _tabController;
  List<DoctorBooking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    try {
      final bookings = await _service.getMyBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bookings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Consultations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: FemFlowColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: FemFlowColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList('confirmed'),
                _buildBookingList('completed'),
                _buildBookingList('cancelled'),
              ],
            ),
    );
  }

  Widget _buildBookingList(String status) {
    final filteredBookings = _bookings.where((b) {
      if (status == 'confirmed') {
        return b.status == 'confirmed';
      }
      return b.status == status;
    }).toList();

    if (filteredBookings.isEmpty) {
      return Center(
        child: Text(
          'No ${status.replaceAll('_', ' ')} consultations.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _buildBookingCard(context, booking);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, DoctorBooking booking) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: booking.id)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.doctorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${booking.appointmentDate} at ${booking.appointmentTime}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_getModeIcon(booking.consultationMode), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(booking.consultationMode.toUpperCase(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.status == 'confirmed') ...[
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Join link will be available before appointment.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${booking.consultationFee.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'pending_payment':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.phone;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.help_outline;
    }
  }
}
