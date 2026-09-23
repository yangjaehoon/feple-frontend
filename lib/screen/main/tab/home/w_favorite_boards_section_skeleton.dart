import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

class FavoriteBoardsSectionSkeleton extends StatelessWidget {
  const FavoriteBoardsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // 실제 콘텐츠(_BoardTile / FavoriteBoardsSection)와 같은 ResponsiveSize로
    // 계산해야 한다 — MediaQuery 폭에 직접 비례시키면 태블릿·폴더블에서
    // ResponsiveSize의 상한 클램프가 빠져 스켈레톤만 커지고 전환 시 튄다.
    final rs = ResponsiveSize(context);
    final cardSize = rs.w(110);
    final listHeight = rs.w(120);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // HomeSectionHeader와 동일한 padding — 다르면 로딩에서 콘텐츠로 바뀔 때
          // 제목이 가로로 밀린다.
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              SkeletonBox(
                width: 3,
                height: 20,
                borderRadius: BorderRadius.circular(AppDimens.barRadius),
              ),
              const SizedBox(width: AppDimens.space8),
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
