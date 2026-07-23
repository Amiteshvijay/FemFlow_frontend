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
    
    final total = invoice.amount;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: FemLyraColors.primary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(BrandConfig.name, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text('Wellness & Health', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('#${invoice.invoiceNumber}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Row - Fixed Layout to prevent overflow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInvoiceInfo('Invoice Date', DateFormat('MMM d, yyyy').format(DateTime.parse(invoice.invoiceDate))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildInvoiceInfo(
                        'Booking ID', 
                        _booking!.bookingIdDisplay,
                        crossAxisAlignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 48),
                
                // Details
                const Text('BILL TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                const Text('Valued FemLyra User', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                const Text('SERVICE DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildServiceRow('Consultation with $doctor', '1 x Consultation', '₹${total.toStringAsFixed(2)}'),
                const Divider(height: 32),
                
                // Summary
                _buildSummaryRow('Consultation Fee', '₹${total.toStringAsFixed(2)}'),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '₹${total.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FemLyraColors.primary)
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PAYMENT STATUS: PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo(String label, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(
          value, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildServiceRow(String title, String subtitle, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
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
