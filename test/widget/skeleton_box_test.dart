import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('SkeletonBox', () {
    testWidgets('지정한 height로 렌더링', (tester) async {
      await tester.pumpWidget(
        _wrap(const SkeletonBox(height: 60)),
      );

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.constraints?.maxHeight ?? 60, greaterThanOrEqualTo(60));
    });

    testWidgets('width 기본값 — 제약 내 최대 너비', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 200, child: SkeletonBox(height: 20))),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('width 명시 시 해당 너비 사용', (tester) async {
      await tester.pumpWidget(
        _wrap(const SkeletonBox(width: 100, height: 20)),
      );

      final size = tester.getSize(find.byType(SkeletonBox));
      expect(size.width, 100);
    });

    testWidgets('borderRadius 전달해도 크래시 없음', (tester) async {
      await tester.pumpWidget(
        _wrap(const SkeletonBox(
          height: 40,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        )),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('애니메이션 진행 중 크래시 없음', (tester) async {
      await tester.pumpWidget(_wrap(const SkeletonBox(height: 30)));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });
}
