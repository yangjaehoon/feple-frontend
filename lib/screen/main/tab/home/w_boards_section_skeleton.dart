import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

class BoardsSectionSkeleton extends StatelessWidget {
  const BoardsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // 기준 390px: 카드 110(0.282), 리스트 높이 120(0.308)
    final cardSize = screenWidth * 0.282;
    final listHeight = screenWidth * 0.308;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              SkeletonBox(
                width: 3,
                height: 20,
                borderRadius: BorderRadius.circular(AppDimens.barRadius),
              ),
              const SizedBox(width: 8),
              const SkeletonBox(width: 130, height: 18),
            ],
          ),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (_, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SkeletonBox(
                width: cardSize,
                height: cardSize,
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
