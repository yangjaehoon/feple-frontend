import 'dart:typed_data';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

/// 이미지 선택/미리보기 박스
class ImagePickerBox extends StatelessWidget {
  final Uint8List? imageData;
  final VoidCallback onTap;
  final String label;

  const ImagePickerBox({
    super.key,
    required this.imageData,
    required this.onTap,
    this.label = '사진 추가',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          height: 240,
          width: 240,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.skyBlueLight,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: imageData == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        color: AppColors.skyBlue, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(imageData!, fit: BoxFit.cover),
                ),
        ),
      ),
    );
  }
}
