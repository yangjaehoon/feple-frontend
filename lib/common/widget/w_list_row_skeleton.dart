import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bounded_responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

/// 리스트/카드형 화면의 초기 로딩 전용 범용 스켈레톤 — 리딩 썸네일(선택) + 2줄 텍스트를
/// itemCount번 반복. 화면별 전용 스켈레톤이 없는 곳에서 스피너 대신 사용.
/// 스크롤 없는 Column을 그대로 bounded 영역(Expanded 등)에 반환하는 화면에서도
/// 쓰이므로(예: w_user_diary_feed_sheet.dart) boundedResponsiveSize로 태블릿급
/// 너비에서의 오버플로를 막는다(ScheduleListSkeleton/SongListSkeleton과 동일 이유).
class ListRowSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showLeading;

  /// 제목·부제 아래에 좋아요/댓글 수 자리(작은 박스 2개) 줄을 추가한다.
  /// (게시글 목록 스켈레톤에서 사용)
  final bool showStatRow;

  /// 항목 사이에 Divider를 넣는다.
  final bool divided;

  const ListRowSkeleton({
    super.key,
    this.itemCount = 3,
    this.showLeading = true,
    this.showStatRow = false,
    this.divided = false,
  });

  @override
  Widget build(BuildContext context) {
    final leadingSize = boundedResponsiveSize(context, 52);

    Widget item(int index) => Padding(
          padding: EdgeInsets.only(
            left: AppDimens.paddingHorizontal,
            right: AppDimens.paddingHorizontal,
            top: index == 0 ? AppDimens.paddingHorizontal : 0,
            bottom: AppDimens.paddingHorizontal,
          ),
          child: Row(
            children: [
              if (showLeading) ...[
                SkeletonBox(
                  width: leadingSize,
                  height: leadingSize,
                  borderRadius: const BorderRadius.all(
                      Radius.circular(AppDimens.radiusSmall)),
                ),
                const SizedBox(width: AppDimens.space12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(height: 14),
                    const SizedBox(height: AppDimens.space8),
                    const SkeletonBox(
                        width: 120,
                        height: 12,
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    if (showStatRow) ...[
                      const SizedBox(height: AppDimens.space8),
                      const Row(
                        children: [
                          SkeletonBox(width: 40, height: 10),
                          SizedBox(width: AppDimens.space12),
                          SkeletonBox(width: 40, height: 10),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

    if (divided) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, index) => item(index),
      );
    }
    return Column(children: List.generate(itemCount, item));
  }
}
