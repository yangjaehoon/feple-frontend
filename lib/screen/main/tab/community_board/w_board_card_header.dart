import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 게시판 카드 상단 헤더 (아이콘 + 제목 + 더보기)
class BoardCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color headerColor;
  final VoidCallback onTap;

  const BoardCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.headerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimens.cardRadiusTiny),
            topRight: Radius.circular(AppDimens.cardRadiusTiny),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingHorizontal, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: headerColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        color: colors.textTitle,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'see_more'.tr(),
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeSm,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: colors.textSecondary, size: AppDimens.iconSizeSm),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: colors.listDivider),
      ],
    );
  }
}
