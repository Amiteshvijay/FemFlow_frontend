import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/health_vault_service.dart';
import 'models/health_document.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../core/storage/token_storage.dart';

class DocumentDetailScreen extends StatefulWidget {
  final int documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final HealthVaultService _service = HealthVaultService();
  HealthDocument? _document;
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _service.getDocumentDetail(widget.documentId);
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('Are you sure you want to remove this document from your vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteDocument(widget.documentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted successfully')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  Future<void> _openFile() async {
    if (_document == null) return;
    
    setState(() => _isDownloading = true);
    try {
      final url = Uri.parse(_document!.fileUrl);
      
      // Load JWT authentication token
      final token = await TokenStorage().getAccessToken();
      
      // Download file with auth headers
      final response = await http.get(
        url,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      final bytes = response.bodyBytes;
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_document!.originalFileName}');
      await file.writeAsBytes(bytes);
      
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
      }
      // Fallback to URL launch
      final url = Uri.parse(_document!.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: FemLyraColors.primary)));
    }

    if (_document == null) {
      return const Scaffold(body: Center(child: Text('Document not found')));
    }

    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Document Detail', style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewCard(),
            const SizedBox(height: 24),
            _buildDetailsSection(),
            const SizedBox(height: 24),
            if (_document!.notes != null && _document!.notes!.isNotEmpty) _buildNotesSection(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isDownloading ? null : _openFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: FemLyraColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isDownloading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('View / Open File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    bool isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(_document!.fileType.toLowerCase());

    return AppCard(
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<String?>(
                  future: TokenStorage().getAccessToken(),
                  builder: (context, snapshot) {
                    final token = snapshot.data;
                    return Image.network(
                      _document!.fileUrl,
                      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFilePlaceholder(),
                    );
                  }
                ),
              )
            : _buildFilePlaceholder(),
      ),
    );
  }

  Widget _buildFilePlaceholder() {
    IconData iconData;
    Color color;

    switch (_document!.fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf_outlined;
        color = Colors.red.shade400;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description_outlined;
        color = Colors.indigo.shade400;
        break;
      default:
        iconData = Icons.insert_drive_file_outlined;
        color = FemLyraColors.textMuted;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData, size: 60, color: color),
        const SizedBox(height: 10),
        Text(
          _document!.fileType.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _document!.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
        ),
        const SizedBox(height: 15),
        _buildInfoRow(Icons.category_outlined, 'Category', _document!.documentTypeLabel),
        _buildInfoRow(Icons.calendar_today_outlined, 'Document Date', _document!.documentDate != null ? DateFormat('MMMM dd, yyyy').format(_document!.documentDate!) : 'Not specified'),
        _buildInfoRow(Icons.file_present_outlined, 'File Info', '${_document!.fileType.toUpperCase()} • ${(_document!.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'),
        _buildInfoRow(Icons.upload_outlined, 'Uploaded On', DateFormat('MMM dd, yyyy').format(_document!.uploadedAt)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FemLyraColors.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemLyraColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FemLyraColors.blushMist.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FemLyraColors.border),
          ),
          child: Text(
            _document!.notes!,
            style: const TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, height: 1.5),
          ),
        ),
      ],
    );
  }
}
