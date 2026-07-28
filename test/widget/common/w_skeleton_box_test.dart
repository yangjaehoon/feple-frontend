import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkeletonBox 렌더링', () {
    testWidgets('지정한 크기로 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonBox(width: 50, height: 20)),
        ),
      );
      await tester.pump();

      final box = tester.getSize(find.byType(SkeletonBox));
      expect(box.width, 50);
      expect(box.height, 20);
    });

    testWidgets('width를 생략하면 부모 너비를 채운다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonBox(height: 20)),
        ),
      );
      await tester.pump();

      final box = tester.getSize(find.byType(SkeletonBox));
      expect(box.width, 800); // 기본 테스트 뷰포트 너비
    });
  });
}
