import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/health_vault_service.dart';
import 'models/health_document.dart';
import 'upload_document_screen.dart';
import 'document_detail_screen.dart';
import 'package:intl/intl.dart';

class HealthVaultScreen extends StatefulWidget {
  const HealthVaultScreen({super.key});

  @override
  State<HealthVaultScreen> createState() => _HealthVaultScreenState();
}

class _HealthVaultScreenState extends State<HealthVaultScreen> {
  final HealthVaultService _service = HealthVaultService();
  List<HealthDocument> _documents = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _filters = [
    {'value': 'all', 'label': 'All', 'icon': Icons.grid_view},
    {'value': 'lab_report', 'label': 'Lab Reports', 'icon': Icons.science_outlined},
    {'value': 'prescription', 'label': 'Prescriptions', 'icon': Icons.medication_outlined},
    {'value': 'ultrasound', 'label': 'Ultrasound', 'icon': Icons.image_outlined},
    {'value': 'pregnancy_test', 'label': 'Pregnancy', 'icon': Icons.child_care_outlined},
    {'value': 'hormone_test', 'label': 'Hormone', 'icon': Icons.biotech_outlined},
    {'value': 'insurance', 'label': 'Insurance', 'icon': Icons.shield_outlined},
    {'value': 'other', 'label': 'Other', 'icon': Icons.folder_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _service.getDocuments(
        documentType: _selectedFilter,
        search: _searchController.text,
      );
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
          'Health Vault',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
                : _documents.isEmpty
                    ? _buildEmptyState()
                    : _buildDocumentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const UploadDocumentScreen())
          );
          if (result == true) _fetchDocuments();
        },
        backgroundColor: FemFlowColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Upload Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Securely store your health documents',
            style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Only you can access your Health Vault',
                style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _fetchDocuments(),
            decoration: InputDecoration(
              hintText: 'Search documents...',
              prefixIcon: const Icon(Icons.search, color: FemFlowColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FemFlowColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FemFlowColors.border),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter['value'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: FilterChip(
                  label: Text(filter['label']),
                  avatar: Icon(filter['icon'], size: 16, color: isSelected ? Colors.white : FemFlowColors.textSecondary),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter['value']);
                    _fetchDocuments();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: FemFlowColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : FemFlowColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), 
                    side: BorderSide(color: isSelected ? FemFlowColors.primary : FemFlowColors.border)
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDocumentList() {
    return RefreshIndicator(
      onRefresh: _fetchDocuments,
      color: FemFlowColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: AppCard(
              onTap: () async {
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id))
                );
                if (result == true) _fetchDocuments();
              },
              child: Row(
                children: [
                  _buildFileIcon(doc.fileType),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doc.documentTypeLabel} • ${doc.documentDate != null ? DateFormat('MMM dd, yyyy').format(doc.documentDate!) : 'No date'}',
                          style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
                        ),
                        if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            doc.notes!,
                            style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileIcon(String type) {
    IconData iconData;
    Color color;

    final normalizedType = type.toLowerCase().replaceAll('.', '');

    switch (normalizedType) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red.shade600;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        iconData = Icons.image;
        color = Colors.blue.shade600;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        color = Colors.indigo.shade600;
        break;
      case 'txt':
        iconData = Icons.article_outlined;
        color = Colors.orange.shade600;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.blueGrey.shade400;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: FemFlowColors.blushMist,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_outlined, size: 60, color: FemFlowColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No documents yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload your first health document to keep it safe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FemFlowColors.textSecondary),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const UploadDocumentScreen())
                );
                if (result == true) _fetchDocuments();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FemFlowColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upload Document', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
