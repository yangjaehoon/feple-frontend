import 'package:feple/common/widget/w_adaptive_refresh_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveRefreshView', () {
    testWidgets('child를 렌더링한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveRefreshView(
              onRefresh: () async {},
              child: const Text('내용'),
            ),
          ),
        ),
      );

      expect(find.text('내용'), findsOneWidget);
    });

    // Platform.isIOS는 실제 호스트 OS 기준이라 이 테스트 환경(맥/CI 모두 비iOS)에서는
    // 항상 false — RefreshIndicator 분기만 검증 가능. Cupertino 분기는 실기기/시뮬레이터
    // 수동 확인 필요.
    testWidgets('RefreshIndicator의 onRefresh가 전달한 콜백과 동일하다', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveRefreshView(
              onRefresh: () async => refreshed = true,
              child: const Text('내용'),
            ),
          ),
        ),
      );

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();

      expect(refreshed, isTrue);
    });
  });
}
