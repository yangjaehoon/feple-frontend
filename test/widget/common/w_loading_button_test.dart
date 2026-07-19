import 'package:feple/common/widget/w_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('LoadingButton 렌더링', () {
    testWidgets('기본 상태에서는 label 텍스트가 보인다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () {}, isLoading: false),
      );

      expect(find.text('확인'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('isLoading=true면 스피너가 보이고 label은 숨겨진다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () {}, isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('확인'), findsNothing);
    });

    testWidgets('isSuccess=true면 체크 아이콘이 보인다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () {}, isSuccess: true),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('icon을 지정하면 label 앞에 아이콘이 함께 보인다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '카카오 로그인', onPressed: () {}, icon: Icons.chat_bubble),
      );

      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
      expect(find.text('카카오 로그인'), findsOneWidget);
    });

    testWidgets('child를 지정하면 label 대신 child가 렌더링된다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(
          onPressed: () {},
          child: const Text('커스텀 child'),
        ),
      );

      expect(find.text('커스텀 child'), findsOneWidget);
    });
  });

  group('LoadingButton 상호작용', () {
    testWidgets('탭하면 onPressed가 호출된다', (tester) async {
      var tapped = false;
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(FilledButton));
      expect(tapped, true);
    });

    testWidgets('isLoading=true면 탭해도 onPressed가 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () => tapped = true, isLoading: true),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(tapped, false);
    });

    testWidgets('isSuccess=true면 탭해도 onPressed가 호출되지 않는다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () {}, isSuccess: true),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('onPressed가 null이면 버튼이 비활성화된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const LoadingButton(label: '확인', onPressed: null),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('LoadingButton 애니메이션', () {
    testWidgets('isSuccess가 false→true로 바뀌면 체크 애니메이션이 시작된다', (tester) async {
      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () {}, isSuccess: false),
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await pumpCommonWidget(
        tester,
        LoadingButton(label: '확인', onPressed: () {}, isSuccess: true),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
