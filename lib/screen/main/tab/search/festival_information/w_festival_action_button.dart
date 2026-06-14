import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class FestivalActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color? color;
  final Color? bgColor;
  final String? label;

  const FestivalActionButton({
    super.key,
    this.onTap,
    required this.icon,
    this.color,
    this.bgColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 20),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: AppDimens.fontSizeTiny,
                fontWeight: FontWeight.w500,
                color: (color ?? Colors.white).withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
