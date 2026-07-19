import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('SecondaryAppBar 렌더링', () {
    testWidgets('title이 렌더링된다', (tester) async {
      await pumpCommonWidget(
        tester,
        Scaffold(appBar: const SecondaryAppBar(title: '제목')),
      );

      expect(find.text('제목'), findsOneWidget);
    });

    testWidgets('actions가 없으면 IconTheme이 렌더링되지 않는다', (tester) async {
      await pumpCommonWidget(
        tester,
        Scaffold(appBar: const SecondaryAppBar(title: '제목')),
      );

      expect(find.byType(IconButton), findsOneWidget); // 뒤로가기만 있음
    });

    testWidgets('actions를 지정하면 함께 렌더링된다', (tester) async {
      await pumpCommonWidget(
        tester,
        Scaffold(
          appBar: SecondaryAppBar(
            title: '제목',
            actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () {})],
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('preferredSize 높이는 AppDimens.appBarHeight이다', (tester) async {
      const appBar = SecondaryAppBar(title: '제목');
      expect(appBar.preferredSize.height, greaterThan(0));
    });
  });

  group('SecondaryAppBar 네비게이션', () {
    testWidgets('뒤로가기 버튼을 탭하면 이전 화면으로 돌아간다', (tester) async {
      await pumpCommonWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(appBar: const SecondaryAppBar(title: '상세')),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('상세'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.text('상세'), findsNothing);
      expect(find.text('go'), findsOneWidget);
    });
  });
}
