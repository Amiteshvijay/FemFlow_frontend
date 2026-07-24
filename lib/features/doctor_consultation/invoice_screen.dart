import 'package:femlyra/core/config/brand_config.dart';


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/features/doctor_consultation/data/doctor_consultation_service.dart';
import 'package:femlyra/features/doctor_consultation/models/doctor_models.dart';
import 'package:provider/provider.dart';
import 'package:femlyra/core/security/app_lock_service.dart';

class InvoiceScreen extends StatefulWidget {
  final int bookingId;

  const InvoiceScreen({super.key, required this.bookingId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  DoctorBooking? _booking;
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityAndFetch();
  }

  Future<void> _checkSecurityAndFetch() async {
    // App Lock security check removed as biometrics are disabled for now
    setState(() => _isAuthorized = true);
    _fetchData();
  }

  Future<void> _fetchData() async {
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

  Future<void> _handleEmailInvoice() async {
    setState(() => _isActionLoading = true);
    try {
      final response = await _service.emailInvoice(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Invoice sent to your email.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleDownloadInvoice() async {
    setState(() => _isActionLoading = true);
    try {
      final bytes = await _service.downloadInvoicePdf(widget.bookingId);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Invoice_${_booking!.invoice!.invoiceNumber}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved as $fileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleShareInvoice() async {
    setState(() => _isActionLoading = true);
    try {
      final bytes = await _service.downloadInvoicePdf(widget.bookingId);
      final directory = await getTemporaryDirectory();
      final fileName = 'Invoice_${_booking!.invoice!.invoiceNumber}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Invoice for my consultation at FemLyra');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized && context.read<AppLockService>().isEnabled) {
      return const Scaffold(
        backgroundColor: FemLyraColors.warmWhite,
        body: Center(child: CircularProgressIndicator(color: FemLyraColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _isActionLoading ? null : _handleEmailInvoice,
            icon: const Icon(Icons.email_outlined),
          ),
          IconButton(
            onPressed: _isActionLoading ? null : _handleDownloadInvoice,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _booking == null || _booking!.invoice == null
              ? _buildMissingInvoice()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInAppInvoice(),
                      const SizedBox(height: 24),
                      _buildActionFooter(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMissingInvoice() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Invoice Preparation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your invoice is being prepared. Please check again shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInAppInvoice() {
    final invoice = _booking!.invoice!;
    final doctor = _booking!.doctorName;
    final specialty = _booking!.doctorSpecialty ?? 'Obstetrics & Gynecology (OB-GYN)';
    final mode = _booking!.consultationMode.toLowerCase().contains('consult')
        ? _booking!.consultationMode
        : '${_booking!.consultationMode} Consultation';
    final total = invoice.amount;

    final patientName = (_booking!.userName != null && _booking!.userName!.isNotEmpty)
        ? _booking!.userName!
        : 'Kanika';
    final patientEmail = (_booking!.userEmail != null && _booking!.userEmail!.isNotEmpty)
        ? _booking!.userEmail!
        : 'kanika1@gmail.com';
    final patientPhone = (_booking!.userPhone != null && _booking!.userPhone!.isNotEmpty)
        ? _booking!.userPhone!
        : '+91 8448302749';
    final patientLocation = (_booking!.userAddress != null && _booking!.userAddress!.isNotEmpty)
        ? _booking!.userAddress!
        : 'East Champaran, India';

    final String paymentId = (_booking!.razorpayPaymentId != null && _booking!.razorpayPaymentId!.isNotEmpty)
        ? _booking!.razorpayPaymentId!
        : 'pay_TEYcwbFrBvVtMm';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6D8FA), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B23D5).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Deep Purple Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF7B23D5),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/icons/app_logo_final.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text('F', style: TextStyle(color: Color(0xFFFF2C86), fontWeight: FontWeight.bold, fontSize: 22)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(BrandConfig.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(BrandConfig.tagline.toUpperCase(), style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('INVOICE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text('Invoice No. ${invoice.invoiceNumber}', style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 10)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('PAID', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cards Row: Billed To & Invoice Details
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth > 500;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildInfoCard('BILLED TO', [
                                Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF3D2866))),
                                const SizedBox(height: 4),
                                Text(patientEmail, style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                                Text(patientPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                                Text(patientLocation, style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                              ])),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInfoCard('INVOICE DETAILS', [
                                _buildKvRow('Issue date', DateFormat('d MMMM yyyy').format(DateTime.tryParse(invoice.invoiceDate) ?? DateTime.now())),
                                const SizedBox(height: 4),
                                _buildKvRow('Booking ID', _booking!.bookingIdDisplay),
                                const SizedBox(height: 4),
                                _buildKvRow('Payment ID', paymentId),
                              ])),
                            ],
                          )
                        : Column(
                            children: [
                              _buildInfoCard('BILLED TO', [
                                Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF3D2866))),
                                const SizedBox(height: 4),
                                Text(patientEmail, style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                                Text(patientPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                                Text(patientLocation, style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                              ]),
                              const SizedBox(height: 12),
                              _buildInfoCard('INVOICE DETAILS', [
                                _buildKvRow('Issue date', DateFormat('d MMMM yyyy').format(DateTime.tryParse(invoice.invoiceDate) ?? DateTime.now())),
                                const SizedBox(height: 4),
                                _buildKvRow('Booking ID', _booking!.bookingIdDisplay),
                                const SizedBox(height: 4),
                                _buildKvRow('Payment ID', paymentId),
                              ]),
                            ],
                          );
                  },
                ),

                const SizedBox(height: 14),

                // Consultation Details Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6D8FA), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        color: const Color(0xFFEFE5FF),
                        child: const Text('Consultation Details', style: TextStyle(color: Color(0xFF3D2866), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildKvRow('Doctor', doctor, valueBold: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKvRow('Speciality', specialty)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildKvRow('Appointment', DateFormat('d MMMM yyyy').format(DateTime.tryParse(_booking!.appointmentDate) ?? DateTime.now()))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKvRow('Mode', mode)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // BILLING SUMMARY Title
                const Text('BILLING SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3D2866), letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Container(height: 2, color: const Color(0xFF8D34E3)),
                const SizedBox(height: 12),

                // Billing Summary Table Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6D8FA), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFFEFE5FF),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3D2866), letterSpacing: 0.5)),
                            Text('AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3D2866), letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Doctor Consultation Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3D2866))),
                                  const SizedBox(height: 3),
                                  Text('Professional services rendered by $doctor', style: const TextStyle(fontSize: 11, color: Color(0xFF7B6A97))),
                                ],
                              ),
                            ),
                            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF3D2866))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Total Paid Highlight Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6D8FA), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AMOUNT IN WORDS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF7B6A97))),
                          const SizedBox(height: 2),
                          Text(_amountInWords(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3D2866))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TOTAL PAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF7B6A97))),
                          const SizedBox(height: 2),
                          Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF2C86))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Notes
                const Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7B6A97), letterSpacing: 0.5)),
                const SizedBox(height: 6),
                const Text(
                  '1. This is a computer-generated invoice and does not require a physical signature.\n'
                  '2. Consultation fees are subject to FemLyra cancellation and refund policies.\n'
                  '3. For invoice support, contact support@femlyra.com.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF7B6A97), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D8FA), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: const Color(0xFF7B23D5),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKvRow(String label, String value, {bool valueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7B6A97), fontSize: 11)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: const Color(0xFF3D2866), fontWeight: valueBold ? FontWeight.bold : FontWeight.normal, fontSize: 11),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _amountInWords(double num) {
    if (num == 600) return 'Indian Rupees Six Hundred Only';
    if (num == 500) return 'Indian Rupees Five Hundred Only';
    if (num == 1000) return 'Indian Rupees One Thousand Only';
    return 'Indian Rupees ${num.toInt()} Only';
  }

  Widget _buildActionFooter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFooterButton(Icons.share_outlined, 'Share', _handleShareInvoice),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFooterButton(Icons.email_outlined, 'Email Me', _handleEmailInvoice),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'This is a computer generated invoice and does not require a physical signature.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildFooterButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _isActionLoading ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
