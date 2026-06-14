import 'dart:typed_data';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 이미지 선택/미리보기 박스
class ImagePickerBox extends StatelessWidget {
  final Uint8List? imageData;
  final VoidCallback onTap;
  final String? label;

  const ImagePickerBox({
    super.key,
    required this.imageData,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
                  border: Border.all(
                    color: colors.activate.withValues(alpha: 0.4),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: imageData == null
                    ? _buildPlaceholder(colors)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(imageData!, fit: BoxFit.cover),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AbstractThemeColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, color: colors.activate, size: 40),
        const SizedBox(height: 8),
        Text(
          label ?? 'photo_add'.tr(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
