import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_skeleton_row_list.dart';
import 'package:flutter/material.dart';

/// ScheduleListTile 모양을 흉내낸 스켈레톤 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
class ScheduleListSkeleton extends StatelessWidget {
  final int itemCount;

  const ScheduleListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonRowList(
      itemCount: itemCount,
      leading: const SkeletonBox(
        width: 42,
        height: 42,
        borderRadius: BorderRadius.all(Radius.circular(21)),
      ),
      lines: const [
        SkeletonBox(height: 14),
        SizedBox(height: 6),
        SkeletonBox(width: 100, height: 11),
        SizedBox(height: 4),
        SkeletonBox(width: 130, height: 11),
      ],
    );
  }
}
