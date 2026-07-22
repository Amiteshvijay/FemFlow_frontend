import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/health_vault_service.dart';
import 'models/health_document.dart';
import 'package:intl/intl.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final HealthVaultService _service = HealthVaultService();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedType;
  DateTime? _selectedDate;
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isUploading = false;
  List<DocumentType> _documentTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    try {
      final types = await _service.getDocumentTypes();
      setState(() => _documentTypes = types);
    } catch (e) {
      // Fail silently or show error
    }
  }

  Future<void> _pickFile() async {
    final appLock = context.read<AppLockService>();
    try {
      appLock.setTrustedExternalFlowActive(true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx'],
        withData: kIsWeb, // Required for web to access bytes
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        final platformFile = result.files.single;
        
        if (platformFile.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be under 10 MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedFileName = platformFile.name;
          _selectedFileSize = platformFile.size;
          
          if (kIsWeb) {
            _selectedFileBytes = platformFile.bytes;
          } else {
            _selectedFile = File(platformFile.path!);
          }
        });

        if (_titleController.text.isEmpty) {
          _titleController.text = platformFile.name.split('.').first;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    } finally {
      appLock.setTrustedExternalFlowActive(false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: FemFlowColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a document type')));
      return;
    }
    if (_selectedFile == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _service.uploadDocument(
        title: _titleController.text,
        documentType: _selectedType!,
        file: _selectedFile,
        bytes: _selectedFileBytes,
        fileName: _selectedFileName,
        notes: _notesController.text,
        documentDate: _selectedDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Document',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Document Title'),
            _buildTextField(_titleController, 'e.g., Blood Test May 2026'),
            const SizedBox(height: 20),
            _buildFieldLabel('Document Type'),
            _buildTypeDropdown(),
            const SizedBox(height: 20),
            _buildFieldLabel('Document Date (Optional)'),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildFieldLabel('Select File'),
            _buildFilePicker(),
            const SizedBox(height: 20),
            _buildFieldLabel('Notes (Optional)'),
            _buildTextField(_notesController, 'Add notes about this document...', maxLines: 3),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Upload Document',
              onPressed: _handleUpload,
              isLoading: _isUploading,
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Your documents are private and protected.',
                style: TextStyle(color: FemFlowColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary, fontSize: 14),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FemFlowColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          hint: const Text('Select category'),
          isExpanded: true,
          items: _documentTypes.map((type) {
            return DropdownMenuItem(
              value: type.value,
              child: Text(type.label),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FemFlowColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null 
                  ? 'Select date' 
                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
              style: TextStyle(color: _selectedDate == null ? Colors.grey : FemFlowColors.textPrimary),
            ),
            const Icon(Icons.calendar_today, size: 18, color: FemFlowColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FemFlowColors.border, style: BorderStyle.solid),
        ),
        child: _selectedFileName == null
            ? Column(
                children: [
                  const Icon(Icons.upload_file, size: 40, color: FemFlowColors.textMuted),
                  const SizedBox(height: 10),
                  const Text('Select document file', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('PDF, JPG, PNG, WEBP, DOC (Max 10MB)', style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedFileSize != null)
                          Text(
                            '${(_selectedFileSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedFile = null;
                      _selectedFileBytes = null;
                      _selectedFileName = null;
                      _selectedFileSize = null;
                    }),
                    child: const Text('Change', style: TextStyle(color: FemFlowColors.primary)),
                  ),
                ],
              ),
      ),
    );
  }
}
