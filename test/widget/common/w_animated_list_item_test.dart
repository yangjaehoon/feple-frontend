import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

void main() {
  group('AnimatedListItem', () {
    testWidgets('child를 렌더링한다', (tester) async {
      await _pump(tester, const AnimatedListItem(index: 0, child: Text('아이템')));

      expect(find.text('아이템'), findsOneWidget);
    });

    testWidgets('index 0은 지연 없이 즉시 페이드인을 시작한다', (tester) async {
      await _pump(tester, const AnimatedListItem(index: 0, child: Text('아이템')));

      await tester.pump(const Duration(milliseconds: 350));
      final transition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(transition.opacity.value, 1.0);
    });

    testWidgets('stagger 딜레이가 있는 인덱스는 딜레이 전에는 투명 상태를 유지한다', (tester) async {
      await _pump(
        tester,
        const AnimatedListItem(
          index: 3,
          staggerDelay: Duration(milliseconds: 100),
          child: Text('아이템'),
        ),
      );

      // 딜레이(300ms) 전에는 아직 페이드인이 시작되지 않아야 한다
      await tester.pump(const Duration(milliseconds: 50));
      final transition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(transition.opacity.value, 0.0);

      // 딜레이 임계값을 넘겨 forward()가 시작되게 한다
      await tester.pump(const Duration(milliseconds: 260));
      // 애니메이션 지속 시간(baseDuration)만큼 추가로 진행시키면 완전히 보인다
      await tester.pump(const Duration(milliseconds: 400));
      final after = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(after.opacity.value, 1.0);
    });

    testWidgets('index가 10 이상이면 stagger 없이 즉시 시작한다', (tester) async {
      await _pump(tester, const AnimatedListItem(index: 20, child: Text('아이템')));

      await tester.pump(const Duration(milliseconds: 350));
      final transition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(transition.opacity.value, 1.0);
    });
  });
}
