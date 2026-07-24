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
                        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(imageData!, fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: _buildChangeBadge(colors),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 사진 선택 후에도 다시 탭해서 바꿀 수 있다는 어포던스가 없어 추가 —
  // 프로필 사진 수정(w_edit_profile.dart)의 카메라 뱃지와 동일한 패턴
  Widget _buildChangeBadge(AbstractThemeColors colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.activate,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
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
