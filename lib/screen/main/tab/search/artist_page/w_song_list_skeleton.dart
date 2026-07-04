import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

/// SongListTile 모양을 흉내낸 스켈레톤 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
class SongListSkeleton extends StatelessWidget {
  final int itemCount;

  const SongListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 12),
              child: const Row(
                children: [
                  SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 13),
                        SizedBox(height: 6),
                        SkeletonBox(width: 80, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < itemCount - 1)
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          ],
        );
      }),
    );
  }
}
