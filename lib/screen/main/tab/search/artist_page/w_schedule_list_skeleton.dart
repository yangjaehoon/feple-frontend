import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_skeleton_row_list.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/constant/app_dimensions.dart';

/// ScheduleListTile 모양을 흉내낸 스켈레톤 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
class ScheduleListSkeleton extends StatelessWidget {
  final int itemCount;

  const ScheduleListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveSize(context).w(42);
    return SkeletonRowList(
      itemCount: itemCount,
      leading: SkeletonBox(
        width: size,
        height: size,
        borderRadius: BorderRadius.all(Radius.circular(size / 2)),
      ),
      lines: const [
        SkeletonBox(height: 14),
        SizedBox(height: AppDimens.space6),
        SkeletonBox(width: 100, height: 11),
        SizedBox(height: AppDimens.space4),
        SkeletonBox(width: 130, height: 11),
      ],
    );
  }
}
