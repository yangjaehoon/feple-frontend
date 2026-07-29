import 'package:feple/common/util/app_route.dart';
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

    testWidgets('PageRouteBuilder 타입이다', (tester) async {
      final route = SlideRoute(builder: (_) => const Text('화면'));

      expect(route, isA<PageRouteBuilder<dynamic>>());
    });
  });
}
