import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 이미지 캐러셀·전체화면 뷰어에서 공통으로 쓰는 "1/3" 형태의 페이지 위치 배지.
class PageIndicatorPill extends StatelessWidget {
  final int currentIndex;
  final int total;

  const PageIndicatorPill({
    super.key,
    required this.currentIndex,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${currentIndex + 1}/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppDimens.fontSizeXxs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
