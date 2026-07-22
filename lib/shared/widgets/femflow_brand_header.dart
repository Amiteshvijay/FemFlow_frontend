import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';

enum BrandHeaderSize { compact, large }

class FemLyraBrandHeader extends StatelessWidget {
  final BrandHeaderSize size;
  final bool showTagline;
  final MainAxisAlignment alignment;

  const FemLyraBrandHeader({
    super.key,
    this.size = BrandHeaderSize.compact,
    this.showTagline = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size == BrandHeaderSize.large ? 80 : 24;
    final double fontSize = size == BrandHeaderSize.large ? 28 : 18;
    final double spacing = size == BrandHeaderSize.large ? 16 : 8;

    Widget logo = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: size == BrandHeaderSize.large ? FemFlowColors.blushMist : FemFlowColors.primary,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/FemLyra_app_icon_1024.png',
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.water_drop,
              color: size == BrandHeaderSize.large ? FemFlowColors.primary : Colors.white,
              size: iconSize * 0.6,
            );
          },
        ),
      ),
    );

    if (size == BrandHeaderSize.large) {
      return Column(
        mainAxisAlignment: alignment,
        children: [
          logo,
          SizedBox(height: spacing),
          Text(
            'FemLyra',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.primary,
            ),
          ),
          if (showTagline) ...[
            const SizedBox(height: 4),
            const Text(
              'Cycle, Health & Care',
              style: TextStyle(
                fontSize: 16,
                color: FemFlowColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: alignment,
        children: [
          logo,
          SizedBox(width: spacing),
          Text(
            'FemLyra',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.primary,
            ),
          ),
        ],
      );
    }
  }
}
