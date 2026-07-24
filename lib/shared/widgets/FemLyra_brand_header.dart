import 'package:femlyra/core/config/brand_config.dart';

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
    final double iconSize = size == BrandHeaderSize.large ? 80 : 28;
    final double fontSize = size == BrandHeaderSize.large ? 28 : 18;
    final double spacing = size == BrandHeaderSize.large ? 16 : 8;

    Widget logo = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: size == BrandHeaderSize.large ? FemLyraColors.blushMist : Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/app_logo_final.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.water_drop_rounded,
                color: size == BrandHeaderSize.large ? FemLyraColors.primary : FemLyraColors.primary,
                size: iconSize * 0.55,
              ),
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
            BrandConfig.name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: FemLyraColors.primary,
            ),
          ),
          if (showTagline) ...[
            const SizedBox(height: 4),
            const Text(
              BrandConfig.tagline,
              style: TextStyle(
                fontSize: 16,
                color: FemLyraColors.textSecondary,
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
            BrandConfig.name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: FemLyraColors.primary,
            ),
          ),
        ],
      );
    }
  }
}
