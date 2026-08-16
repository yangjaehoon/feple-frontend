import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class FestivalActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color? color;
  final Color? bgColor;
  final String? label;
  final bool isLoading;

  const FestivalActionButton({
    super.key,
    this.onTap,
    required this.icon,
    this.color,
    this.bgColor,
    this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color ?? Colors.white,
                    ),
                  )
                : Icon(icon, color: color ?? Colors.white, size: 20),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label!,
                maxLines: 1,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
