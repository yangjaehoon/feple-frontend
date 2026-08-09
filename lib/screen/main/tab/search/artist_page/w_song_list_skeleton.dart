import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_skeleton_row_list.dart';
import 'package:flutter/material.dart';

/// SongListTile 모양을 흉내낸 스켈레톤 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
class SongListSkeleton extends StatelessWidget {
  final int itemCount;

  const SongListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonRowList(
      itemCount: itemCount,
      leading: const SkeletonBox(
        width: 52,
        height: 52,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      lines: const [
        SkeletonBox(height: 13),
        SizedBox(height: 6),
        SkeletonBox(width: 80, height: 11),
      ],
    );
  }
}
