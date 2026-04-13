import 'package:easy_localization/easy_localization.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal, vertical: 0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.cardRadius),
          topRight: Radius.circular(AppDimens.cardRadius),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: AppDimens.iconSizeLg),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDimens.fontSizeLg,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: AppDimens.iconSizeSm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
