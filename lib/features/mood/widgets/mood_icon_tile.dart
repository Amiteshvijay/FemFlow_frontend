import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../models/mood_models.dart';

class MoodIconTile extends StatelessWidget {
  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const MoodIconTile({
    super.key,
    required this.mood,
    required this.isSelected,
    required this.onTap,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? FemLyraColors.primary : FemLyraColors.blushMist,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: FemLyraColors.primary, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: FemLyraColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Text(
              mood.emoji,
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mood.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? FemLyraColors.primary : FemLyraColors.textSecondary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
