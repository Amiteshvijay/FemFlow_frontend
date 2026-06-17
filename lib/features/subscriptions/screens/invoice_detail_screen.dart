import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/network/api_client.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Invoice Detail'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: FemFlowColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _isDownloading ? null : () => _shareInvoice(context),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _isDownloading ? null : () => _downloadInvoice(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isDownloading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(color: FemFlowColors.primary),
              ),
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildBillingSection(context),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 48),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Successful',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Invoice # ${widget.invoice.invoiceNumber}',
                  style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subscription Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          _buildDetailRow('Plan Name', widget.invoice.planName ?? 'Premium Subscription'),
          _buildDetailRow('Billing Date', DateFormat('MMMM dd, yyyy').format(widget.invoice.createdAt)),
          _buildDetailRow('Status', widget.invoice.status.toUpperCase(), valueColor: Colors.green),
          _buildDetailRow('Payment Mode', 'Razorpay'),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    
    return AppCard(
      color: Colors.grey.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Billing Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          _buildSummaryRow('Subscription Fee', currencyFormat.format(widget.invoice.totalAmount)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                currencyFormat.format(widget.invoice.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FemFlowColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FemFlowColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? FemFlowColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FemFlowColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : () => _downloadInvoice(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FemFlowColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : () => _shareInvoice(context),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: FemFlowColors.primary,
              side: const BorderSide(color: FemFlowColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Text(
            'This is a computer-generated invoice.',
            style: TextStyle(color: FemFlowColors.textMuted, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'Questions? Contact support@femflow.in',
            style: TextStyle(color: FemFlowColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadInvoice(BuildContext context) async {
    final appLock = context.read<AppLockService>();
    final messenger = ScaffoldMessenger.of(context);
    final baseUrl = ApiClient().baseUrl;
    final downloadUrl = '$baseUrl/subscriptions/invoices/${widget.invoice.id}/download/';
    final token = await context.read<SubscriptionProvider>().getToken();

    setState(() => _isDownloading = true);
    appLock.setTrustedExternalFlowActive(true);

    try {
      final response = await http.get(Uri.parse(downloadUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/Invoice_${widget.invoice.invoiceNumber}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          await OpenFilex.open(filePath);
        }
      } else {
        throw Exception('Failed to download invoice: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
      // Small delay for app lock
      Future.delayed(const Duration(milliseconds: 500), () {
        appLock.setTrustedExternalFlowActive(false);
      });
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    final appLock = context.read<AppLockService>();
    final messenger = ScaffoldMessenger.of(context);
    final baseUrl = ApiClient().baseUrl;
    final downloadUrl = '$baseUrl/subscriptions/invoices/${widget.invoice.id}/download/';
    final token = await context.read<SubscriptionProvider>().getToken();

    setState(() => _isDownloading = true);
    appLock.setTrustedExternalFlowActive(true);

    try {
      final response = await http.get(Uri.parse(downloadUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/Invoice_${widget.invoice.invoiceNumber}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          await Share.shareXFiles(
            [XFile(filePath)], 
            text: 'My FemFlow Subscription Invoice: ${widget.invoice.invoiceNumber}'
          );
        }
      } else {
        throw Exception('Failed to download invoice for sharing');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        appLock.setTrustedExternalFlowActive(false);
      });
    }
  }
}
