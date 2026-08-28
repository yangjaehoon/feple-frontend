import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// leading(아바타/썸네일) + 오른쪽 텍스트 라인들을 itemCount만큼 반복하고 구분선을
/// 넣는 목록형 스켈레톤 뼈대. 실제 타일 모양을 정확히 흉내내야 하는 화면별
/// 스켈레톤(ScheduleListSkeleton, SongListSkeleton 등)이 leading/lines만 바꿔 공유한다.
class SkeletonRowList extends StatelessWidget {
  final int itemCount;
  final Widget leading;
  final List<Widget> lines;

  const SkeletonRowList({
    super.key,
    required this.itemCount,
    required this.leading,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingHorizontal,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines,
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
