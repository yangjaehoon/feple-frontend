import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 마이페이지 섹션 헤더 우측의 "전체보기 >" 텍스트 버튼.
/// [onTap]이 null이면 비활성(로딩 중 등).
class SectionSeeAllButton extends StatelessWidget {
  final VoidCallback? onTap;

  const SectionSeeAllButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'see_all'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: colors.activate,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: colors.activate),
        ],
      ),
    );
  }
}
