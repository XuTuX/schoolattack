import 'package:flutter/material.dart';
import '../app_theme.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color borderNeonColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.blur = 12.0,
    this.borderNeonColor = const Color(0xFF2DD4BF),
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.panelBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderNeonColor.withValues(alpha: 0.9),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.25),
            blurRadius: 0,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.55),
            blurRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}
