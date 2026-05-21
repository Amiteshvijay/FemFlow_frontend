import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final BorderSide? border;
  final VoidCallback? onTap;
  final double? width;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.border,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius ?? 16),
      child: Container(
        width: width,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? FemFlowColors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          border: Border.all(
            color: border?.color ?? FemFlowColors.border,
            width: border?.width ?? 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
