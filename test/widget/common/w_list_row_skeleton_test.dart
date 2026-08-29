import 'package:feple/common/widget/w_list_row_skeleton.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListRowSkeleton 렌더링', () {
    testWidgets('기본값은 리딩 썸네일 포함 3개 행을 보여준다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ListRowSkeleton())),
      );

      // 행당 SkeletonBox 3개(리딩 1 + 텍스트 2) × 3행 = 9개
      expect(find.byType(SkeletonBox), findsNWidgets(9));
    });

    testWidgets('showLeading false이면 리딩 썸네일이 빠진다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ListRowSkeleton(itemCount: 2, showLeading: false)),
        ),
      );

      // 행당 SkeletonBox 2개(텍스트만) × 2행 = 4개
      expect(find.byType(SkeletonBox), findsNWidgets(4));
    });

    testWidgets('itemCount만큼 행을 반복한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ListRowSkeleton(itemCount: 1)),
        ),
      );

      expect(find.byType(SkeletonBox), findsNWidgets(3));
    });

    testWidgets('showStatRow이면 행마다 stat 박스 2개가 추가된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListRowSkeleton(
              itemCount: 1,
              showLeading: false,
              showStatRow: true,
            ),
          ),
        ),
      );

      // 텍스트 2개 + stat 2개 = 4개
      expect(find.byType(SkeletonBox), findsNWidgets(4));
    });

    testWidgets('divided이면 항목 사이에 Divider가 있다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListRowSkeleton(itemCount: 3, divided: true),
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2)); // 3항목 사이 2개
    });
  });
}
