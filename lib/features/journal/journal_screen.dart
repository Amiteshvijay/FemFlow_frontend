import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/journal_service.dart';
import 'models/journal_entry.dart';
import 'models/note_category.dart';
import 'create_note_screen.dart';
import 'note_detail_screen.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalService _service = JournalService();
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _service.getEntries(
        type: _selectedFilter,
        search: _searchController.text,
      );
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          'FemFlow Journal',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
                : _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildEntryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateNoteScreen()),
          );
          if (result == true) _fetchEntries();
        },
        backgroundColor: FemFlowColors.primary,
        icon: const Icon(Icons.edit_calendar, color: Colors.white),
        label: const Text('New Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Your private cycle and wellness diary',
            style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    int total = _entries.length;
    int pinned = _entries.where((e) => e.isPinned).length;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _buildSummaryCard('Total Notes', total.toString(), FemFlowColors.primary),
          _buildSummaryCard('Pinned', pinned.toString(), Colors.orange),
          _buildSummaryCard('Privacy', 'Active', Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        color: color.withValues(alpha: 0.1),
        border: BorderSide.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
          ],
        ),
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
            onSubmitted: (_) => _fetchEntries(),
            decoration: InputDecoration(
              hintText: 'Search your journal...',
              prefixIcon: const Icon(Icons.search, color: FemFlowColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
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
            itemCount: NoteCategory.all.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : NoteCategory.all[index - 1];
              final value = isAll ? 'all' : category!.value;
              final label = isAll ? 'All' : category!.label;
              final isSelected = _selectedFilter == value;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = value);
                    _fetchEntries();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: isAll ? FemFlowColors.primary : category?.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : FemFlowColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.transparent : FemFlowColors.border),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntryList() {
    return RefreshIndicator(
      onRefresh: _fetchEntries,
      color: FemFlowColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final category = NoteCategory.fromValue(entry.noteType);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NoteDetailScreen(entryId: entry.id!)),
                );
                if (result == true) _fetchEntries();
              },
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(category.icon, size: 16, color: category.color),
                                const SizedBox(width: 8),
                                Text(
                                  category.label,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: category.color),
                                ),
                                const Spacer(),
                                if (entry.isPinned) const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  entry.date != null ? DateFormat('MMM dd').format(DateTime.parse(entry.date!)) : '',
                                  style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.content,
                              style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (entry.tags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                children: entry.tags.take(3).map((tag) => _buildTag(tag)).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FemFlowColors.blushMist,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(fontSize: 10, color: FemFlowColors.primary, fontWeight: FontWeight.w600),
      ),
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
            child: const Icon(Icons.auto_stories_outlined, size: 60, color: FemFlowColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No journal entries yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start with one small note about how your body feels today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FemFlowColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
