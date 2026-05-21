import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../mood/data/mood_service.dart';
import '../mood/models/mood_models.dart';

class FullMoodPickerScreen extends StatefulWidget {
  final Set<String> initialSelected;

  const FullMoodPickerScreen({super.key, required this.initialSelected});

  @override
  State<FullMoodPickerScreen> createState() => _FullMoodPickerScreenState();
}

class _FullMoodPickerScreenState extends State<FullMoodPickerScreen> {
  final MoodService _moodService = MoodService();
  late Set<String> _selectedMoods;
  String _searchQuery = '';
  MoodCatalog? _catalog;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMoods = Set.from(widget.initialSelected);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await _moodService.getMoodCatalog();
      if (mounted) {
        setState(() {
          _catalog = catalog;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Mood', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_selectedMoods.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _selectedMoods.clear()),
              child: const Text('Clear all', style: TextStyle(color: FemFlowColors.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How are you feeling today?',
                        style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search moods',
                          prefixIcon: const Icon(Icons.search, color: FemFlowColors.textMuted),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (_catalog != null) ...[
                        _buildCategorySection('General', _catalog!.general),
                        _buildCategorySection('Positive', _catalog!.positive),
                        _buildCategorySection('Negative', _catalog!.negative),
                        _buildCategorySection('Cycle-related', _catalog!.cycleRelated),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: PrimaryButton(
                    label: 'Save Mood ${_selectedMoods.isNotEmpty ? "(${_selectedMoods.length})" : ""}',
                    onPressed: () => Navigator.pop(context, _selectedMoods),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategorySection(String title, List<Mood> moods) {
    final filteredMoods = moods
        .where((m) => m.label.toLowerCase().contains(_searchQuery))
        .toList();

    if (filteredMoods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.textPrimary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredMoods.map((mood) {
            final isSelected = _selectedMoods.contains(mood.key);
            return _buildSelectableChip(mood, isSelected);
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSelectableChip(Mood mood, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMoods.remove(mood.key);
          } else {
            _selectedMoods.add(mood.key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FemFlowColors.blushMist : FemFlowColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? FemFlowColors.primary : FemFlowColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              mood.label,
              style: TextStyle(
                color: isSelected ? FemFlowColors.primary : FemFlowColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
