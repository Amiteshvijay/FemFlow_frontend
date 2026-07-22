import 'package:flutter/material.dart';
import 'package:FemLyra/core/theme/FemLyra_colors.dart';
import 'package:FemLyra/shared/widgets/app_card.dart';
import 'models/doctor_models.dart';
import 'my_doctor_bookings_screen.dart';

class DoctorPaymentSuccessScreen extends StatelessWidget {
  final DoctorProfile doctor;
  final DateTime date;
  final String time;
  final String mode;
  final int bookingId;

  const DoctorPaymentSuccessScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.mode,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Booking Confirmed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your consultation is booked. You will receive joining details before the appointment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow('Doctor', doctor.fullName),
                        _buildDetailRow('Date', dateStr),
                        _buildDetailRow('Time', time),
                        _buildDetailRow('Mode', mode.toUpperCase()),
                        _buildDetailRow('Booking ID', '#$bookingId'),
                        _buildDetailRow('Status', 'PAID', isStatus: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MyDoctorBookingsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FemLyraColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('View My Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isStatus ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
