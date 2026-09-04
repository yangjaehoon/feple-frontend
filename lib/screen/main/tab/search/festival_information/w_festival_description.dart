import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 페스티벌 포스터 하단의 "페스티벌 소개" 접기/펼치기 섹션.
class FestivalDescriptionSection extends StatelessWidget {
  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  const FestivalDescriptionSection({
    super.key,
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
              height: 1, color: Colors.white.withValues(alpha: 0.15)),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: AppDimens.space6),
                Text(
                  'festival_info'.tr(),
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        // 접기 애니메이션: Text는 항상 full-width로 레이아웃되고(리플로우 없음),
        // ClipRect + AnimatedAlign(heightFactor)가 높이만 1→0으로 줄여 위로 밀어 올린다.
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topLeft,
            heightFactor: expanded ? 1.0 : 0.0,
            duration: AppDimens.animFast,
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space10),
      ],
    );
  }
}
