import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefreshableCenter 렌더링', () {
    testWidgets('child를 보여준다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RefreshableCenter(child: Text('안내 문구'))),
        ),
      );

      expect(find.text('안내 문구'), findsOneWidget);
    });

    testWidgets('SingleChildScrollView로 감싸 pull-to-refresh 제스처를 지원한다', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async => refreshed = true,
              child: const RefreshableCenter(child: Text('안내 문구')),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.fling(find.text('안내 문구'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });
  });
}
