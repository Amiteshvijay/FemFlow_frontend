import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/symptom_models.dart';
import 'widgets/category_chip_group.dart';

class FullSymptomsPickerScreen extends StatefulWidget {
  final Set<String> initialSelected;

  const FullSymptomsPickerScreen({super.key, required this.initialSelected});

  @override
  State<FullSymptomsPickerScreen> createState() => _FullSymptomsPickerScreenState();
}

class _FullSymptomsPickerScreenState extends State<FullSymptomsPickerScreen> {
  late Set<String> _selectedSymptoms;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSymptoms = Set.from(widget.initialSelected);
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
        title: const Text('Select Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_selectedSymptoms.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _selectedSymptoms.clear()),
              child: const Text('Clear all', style: TextStyle(color: FemFlowColors.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose everything you feel today.',
                  style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search symptoms',
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: SymptomConstants.categories.length,
              itemBuilder: (context, index) {
                final category = SymptomConstants.categories[index];
                
                // Filter items based on search
                final filteredItems = category.items
                    .where((item) => item.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                  return const SizedBox.shrink();
                }

                return CategoryChipGroup(
                  title: category.title,
                  items: filteredItems,
                  selectedItems: _selectedSymptoms,
                  onSelectionChanged: (item, isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedSymptoms.add(item);
                      } else {
                        _selectedSymptoms.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: PrimaryButton(
              label: 'Save Symptoms ${_selectedSymptoms.isNotEmpty ? "(${_selectedSymptoms.length})" : ""}',
              onPressed: () => Navigator.pop(context, _selectedSymptoms),
            ),
          ),
        ],
      ),
    );
  }
}
