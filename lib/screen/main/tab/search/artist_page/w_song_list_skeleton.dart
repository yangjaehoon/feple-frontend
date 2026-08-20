import 'package:feple/common/util/bounded_responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_skeleton_row_list.dart';
import 'package:flutter/material.dart';

/// SongListTile 모양을 흉내낸 스켈레톤 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
/// 스크롤 없는 Column 기반 목록(SkeletonRowList)이라 boundedResponsiveSize로 태블릿급
/// 너비에서의 오버플로를 막는다(위젯 테스트로 재현·확인).
class SongListSkeleton extends StatelessWidget {
  final int itemCount;

  const SongListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = boundedResponsiveSize(context, 52);
    return SkeletonRowList(
      itemCount: itemCount,
      leading: SkeletonBox(
        width: thumbnailSize,
        height: thumbnailSize,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      lines: const [
        SkeletonBox(height: 13),
        SizedBox(height: 6),
        SkeletonBox(width: 80, height: 11),
      ],
    );
  }
}
