import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_skeleton_row_list.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/constant/app_dimensions.dart';

/// SongListTile 모양을 흉내낸 스켈레톤 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
class SongListSkeleton extends StatelessWidget {
  final int itemCount;

  const SongListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = ResponsiveSize(context).w(52);
    return SkeletonRowList(
      itemCount: itemCount,
      leading: SkeletonBox(
        width: thumbnailSize,
        height: thumbnailSize,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      lines: const [
        SkeletonBox(height: 13),
        SizedBox(height: AppDimens.space6),
        SkeletonBox(width: 80, height: 11),
      ],
    );
  }
}
