import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';

class CompactChipSection extends StatelessWidget {
  final String title;
  final List<String> defaultItems;
  final Set<String> selectedItems;
  final VoidCallback onViewAll;
  final Function(String, bool) onToggle;
  final String Function(String)? labelProvider;

  const CompactChipSection({
    super.key,
    required this.title,
    required this.defaultItems,
    required this.selectedItems,
    required this.onViewAll,
    required this.onToggle,
    this.labelProvider,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine which chips to show
    final List<String> itemsToShow = [];
    
    // Always show selected items first
    itemsToShow.addAll(selectedItems);
    
    // Fill remaining with default items that aren't already selected
    for (var item in defaultItems) {
      if (!itemsToShow.contains(item)) {
        itemsToShow.add(item);
      }
      if (itemsToShow.length >= 8) break; // Hard limit for compact view
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FemFlowColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Row(
                children: [
                  const Text(
                    'View all',
                    style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 16, color: FemFlowColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: itemsToShow.map((item) {
            final isSelected = selectedItems.contains(item);
            final displayLabel = labelProvider != null ? labelProvider!(item) : item;
            return _buildSelectableChip(item, displayLabel, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectableChip(String value, String displayLabel, bool isSelected) {
    return GestureDetector(
      onTap: () => onToggle(value, !isSelected),
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
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? FemFlowColors.primary : FemFlowColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
