import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 타임테이블 헤더의 스테이지 이름 셀.
/// height를 생략하면 부모(SizedBox 등)가 높이를 결정한다.
class TimetableStageCell extends StatelessWidget {
  final String stage;
  final Color color;
  final double width;
  final double? height;

  const TimetableStageCell({
    super.key,
    required this.stage,
    required this.color,
    required this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: colors.listDivider),
          right: BorderSide(color: colors.listDivider, width: 0.5),
        ),
      ),
      child: Text(
        stage,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXs,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 타임테이블 헤더의 좌측 상단 코너 셀 (시간 열 위).
/// height를 생략하면 부모가 높이를 결정한다.
class TimetableCornerCell extends StatelessWidget {
  final double width;
  final double? height;

  const TimetableCornerCell({
    super.key,
    required this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.listDivider),
          right: BorderSide(color: colors.listDivider),
        ),
      ),
    );
  }
}
