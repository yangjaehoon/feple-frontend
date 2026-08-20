import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/responsive_size.dart';

/// 리스트/카드형 화면의 초기 로딩 전용 범용 스켈레톤 — 리딩 썸네일(선택) + 2줄 텍스트를
/// itemCount번 반복. 화면별 전용 스켈레톤이 없는 곳에서 스피너 대신 사용.
class ListRowSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showLeading;

  const ListRowSkeleton({super.key, this.itemCount = 3, this.showLeading = true});

  @override
  Widget build(BuildContext context) {
    final leadingSize = ResponsiveSize(context).w(52);
    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
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
                  borderRadius: const BorderRadius.all(Radius.circular(AppDimens.radiusSmall)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(height: 14),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 12, borderRadius: const BorderRadius.all(Radius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
