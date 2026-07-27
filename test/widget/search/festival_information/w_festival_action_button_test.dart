import 'package:feple/screen/main/tab/search/festival_information/w_festival_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

void main() {
  group('FestivalActionButton 렌더링', () {
    testWidgets('아이콘과 라벨을 보여준다', (tester) async {
      await _pump(
        tester,
        const FestivalActionButton(icon: Icons.share_rounded, label: '공유'),
      );

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.text('공유'), findsOneWidget);
    });

    testWidgets('label이 없으면 텍스트를 보여주지 않는다', (tester) async {
      await _pump(tester, const FestivalActionButton(icon: Icons.share_rounded));

      expect(find.byType(Text), findsNothing);
    });
  });

  group('FestivalActionButton 탭', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        FestivalActionButton(icon: Icons.share_rounded, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(FestivalActionButton));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
