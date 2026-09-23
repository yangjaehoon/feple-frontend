import 'package:feple/common/widget/w_list_row_skeleton.dart';
import 'package:flutter/material.dart';

/// 게시글 목록 로딩 스켈레톤.
///
/// [PostListTile]과 같은 구성(아바타 + 제목·내용 + 통계 행)이라야 로딩에서
/// 콘텐츠로 바뀔 때 레이아웃이 튀지 않는다 — 게시판 목록·검색 결과가 공유한다.
class PostSkeletonList extends StatelessWidget {
  final int itemCount;

  const PostSkeletonList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) => ListRowSkeleton(
        showStatRow: true,
        divided: true,
        itemCount: itemCount,
      );
}
