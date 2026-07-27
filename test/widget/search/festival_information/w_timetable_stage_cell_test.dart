import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_skeleton.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_stage_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('TimetableStageCell', () {
    testWidgets('스테이지 이름을 보여준다', (tester) async {
      await _pump(
        tester,
        const TimetableStageCell(stage: '메인 스테이지', color: Colors.blue, width: 100),
      );

      expect(find.text('메인 스테이지'), findsOneWidget);
    });
  });

  group('TimetableCornerCell', () {
    testWidgets('빈 코너 셀을 렌더링한다', (tester) async {
      await _pump(tester, const TimetableCornerCell(width: 40));

      expect(find.byType(TimetableCornerCell), findsOneWidget);
    });
  });

  group('TimetableSkeleton', () {
    testWidgets('스켈레톤 박스들을 렌더링한다', (tester) async {
      await _pump(tester, const TimetableSkeleton());

      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });
}
