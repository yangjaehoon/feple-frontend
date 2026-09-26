import 'dart:async';

import 'package:feple/common/util/app_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlideRoute', () {
    testWidgets('push하면 builder가 만든 화면으로 이동한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                SlideRoute(builder: (_) => const Text('다음 화면')),
              ),
              child: const Text('이동'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('이동'));
      await tester.pumpAndSettle();

      expect(find.text('다음 화면'), findsOneWidget);
    });

    testWidgets('iOS 엣지 스와이프 뒤로가기를 지원하는 CupertinoRouteTransitionMixin 타입이다', (tester) async {
      final route = SlideRoute(builder: (_) => const Text('화면'));

      expect(route, isA<CupertinoRouteTransitionMixin<dynamic>>());
    });
  });

  group('popRouteWithResult', () {
    /// 화면을 push하고, 그 화면의 context와 push 호출부가 받은 결과를 돌려준다.
    Future<(BuildContext, ValueGetter<String?>)> pushScreen(
      WidgetTester tester,
    ) async {
      String? received;
      late BuildContext screenContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                received = await Navigator.push<String>(
                  context,
                  SlideRoute<String>(
                    builder: (_) => Builder(
                      builder: (inner) {
                        screenContext = inner;
                        return const Text('내 화면');
                      },
                    ),
                  ),
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      return (screenContext, () => received);
    }

    testWidgets('최상단이면 결과와 함께 이 화면을 닫는다', (tester) async {
      final (screenContext, received) = await pushScreen(tester);

      popRouteWithResult(screenContext, '완료');
      await tester.pumpAndSettle();

      expect(find.text('내 화면'), findsNothing);
      expect(received(), '완료');
    });

    // 회귀 방지: 비동기 작업이 끝나는 사이 다이얼로그가 떠 있으면 Navigator.pop은
    // 그 다이얼로그를 닫고, 기대 타입과 다른 결과가 didPop에 전달돼 TypeError가
    // 난다(이메일 인증 폴링 + 취소 확인 다이얼로그에서 실제로 발생 가능).
    testWidgets('위에 다이얼로그가 떠 있어도 다이얼로그가 아닌 이 화면을 닫는다', (tester) async {
      final (screenContext, received) = await pushScreen(tester);

      bool dialogClosed = false;
      Object? dialogResult;
      unawaited(
        showDialog<bool>(
          context: screenContext,
          builder: (_) => const Text('다이얼로그'),
        ).then((value) {
          dialogClosed = true;
          dialogResult = value;
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('다이얼로그'), findsOneWidget);

      popRouteWithResult(screenContext, '완료');
      await tester.pumpAndSettle();

      expect(find.text('다이얼로그'), findsNothing);
      expect(find.text('내 화면'), findsNothing);
      expect(received(), '완료', reason: '결과는 다이얼로그가 아니라 push 호출부로 가야 한다');
      expect(dialogClosed, isTrue);
      expect(dialogResult, isNull, reason: '다이얼로그는 자기 타입에 맞는 null로 닫혀야 한다');
    });

    testWidgets('최초 라우트에서는 스택을 비우지 않는다', (tester) async {
      late BuildContext homeContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              homeContext = context;
              return const Text('첫 화면');
            },
          ),
        ),
      );

      popRouteWithResult(homeContext, true);
      await tester.pumpAndSettle();

      expect(find.text('첫 화면'), findsOneWidget);
    });
  });
}
