import 'package:feple/common/constant/timetable_colors.dart';
import 'package:flutter/material.dart';

/// stages 리스트 내 위치를 기준으로 순환 배정되는 타임테이블 스테이지 색상.
Color timetableStageColor(String stage, List<String> stages) {
  final colorIndex = stages.indexOf(stage) % kStageColors.length;
  return kStageColors[colorIndex < 0 ? 0 : colorIndex];
}

/// 셀 높이가 분 단위 픽셀 환산으로 고정돼 있어 텍스트 배율이 커지면 카드 안
/// 텍스트가 넘침 → 타임테이블 그리드 안에서만 배율을 별도로 제한한다.
Widget clampTimetableTextScale(BuildContext context, {required Widget child}) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
    ),
    child: child,
  );
}

/// 운영 항목(공연이 아닌 행사 등)은 스테이지 구분 없이 모든 열에 걸쳐 표시된다.
/// 그날 실제 공연이 없어 stages가 비어있어도 카드가 사라지지 않도록 최소 1칸을 보장한다.
int opsColumnCount(List<String> stages) => stages.isEmpty ? 1 : stages.length;

/// 타임테이블 카드 한 칸의 배치 좌표/크기. compact/fullscreen 그리드가 카드
/// 위젯 자체는 각자 다르게 그리지만(폰트 크기 적응 여부 등), 열 안에서의
/// 위치 계산(좌우 3px/6px 인셋, 상하 2px 인셋)은 동일하다.
({double left, double top, double width, double height}) timetableCardRect({
  required int columnIndex,
  required double stageW,
  required double topPad,
  required double rawTop,
  required double height,
}) =>
    (
      left: columnIndex * stageW + 3,
      top: topPad + rawTop + 2,
      width: stageW - 6,
      height: height,
    );
