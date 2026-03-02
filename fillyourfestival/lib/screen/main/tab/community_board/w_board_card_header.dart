import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
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
    final rs = ResponsiveSize(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal, vertical: 10),
      width: double.infinity,
      height: rs.h(AppDimens.boardHeaderHeight),
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
            const Row(
              children: [
                Text(
                  "더보기",
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
