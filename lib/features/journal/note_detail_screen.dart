import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/journal_service.dart';
import 'models/journal_entry.dart';
import 'models/note_category.dart';
import 'create_note_screen.dart';
import 'package:intl/intl.dart';

class NoteDetailScreen extends StatefulWidget {
  final int entryId;
  const NoteDetailScreen({super.key, required this.entryId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final JournalService _service = JournalService();
  JournalEntry? _entry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final entry = await _service.getEntryDetail(widget.entryId);
      setState(() {
        _entry = entry;
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
        title: const Text('Delete Journal Entry?'),
        content: const Text('Are you sure you want to remove this entry from your journal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteEntry(widget.entryId);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: FemLyraColors.primary)));
    }

    if (_entry == null) {
      return const Scaffold(body: Center(child: Text('Entry not found')));
    }

    final category = NoteCategory.fromValue(_entry!.noteType);

    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_entry!.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.orange),
            onPressed: () async {
              await _service.togglePin(_entry!.id!, !_entry!.isPinned);
              _fetchDetail();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateNoteScreen(initialEntry: _entry)),
                ).then((res) { if (res == true) _fetchDetail(); });
              } else if (val == 'delete') {
                _handleDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Entry')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Entry')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryBadge(category),
            const SizedBox(height: 24),
            Text(
              _entry!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _entry!.date != null ? DateFormat('MMMM dd, yyyy').format(DateTime.parse(_entry!.date!)) : '',
              style: const TextStyle(fontSize: 14, color: FemLyraColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildInsightStrip(),
            const SizedBox(height: 32),
            AppCard(
              width: double.infinity,
              child: Text(
                _entry!.content,
                style: const TextStyle(fontSize: 16, color: FemLyraColors.textPrimary, height: 1.6),
              ),
            ),
            if (_entry!.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _entry!.tags.map((tag) => _buildTag(tag)).toList(),
              ),
            ],
            const SizedBox(height: 40),
            if (_entry!.isPrivate) _buildPrivacyIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(NoteCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cat.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cat.icon, size: 20, color: cat.color),
          const SizedBox(width: 10),
          Text(
            cat.label,
            style: TextStyle(fontWeight: FontWeight.bold, color: cat.color),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStrip() {
    return Row(
      children: [
        if (_entry!.mood != null) _buildInsightCard('Mood', _entry!.mood!, Icons.sentiment_satisfied_outlined, Colors.purple),
        if (_entry!.painLevel > 0) _buildInsightCard('Pain', '${_entry!.painLevel}/10', Icons.healing_outlined, Colors.orange),
        if (_entry!.energyLevel != null) _buildInsightCard('Energy', _entry!.energyLevel!, Icons.bolt, Colors.green),
      ],
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FemLyraColors.blushMist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(fontSize: 12, color: FemLyraColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPrivacyIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline, size: 14, color: FemLyraColors.textMuted),
        SizedBox(width: 4),
        Text(
          'Private note • Only you can see this',
          style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
        ),
      ],
    );
  }
}
