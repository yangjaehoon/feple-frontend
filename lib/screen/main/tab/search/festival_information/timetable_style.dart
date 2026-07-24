import 'package:feple/common/constant/timetable_colors.dart';
import 'package:flutter/material.dart';

/// stages 리스트 내 위치를 기준으로 순환 배정되는 타임테이블 스테이지 색상.
Color timetableStageColor(String stage, List<String> stages) {
  final colorIndex = stages.indexOf(stage) % kStageColors.length;
  return kStageColors[colorIndex < 0 ? 0 : colorIndex];
}
