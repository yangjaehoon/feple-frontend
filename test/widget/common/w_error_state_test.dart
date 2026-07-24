import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('ErrorState 렌더링', () {
    testWidgets('메시지와 기본 아이콘이 렌더링된다', (tester) async {
      await pumpCommonWidget(tester, const ErrorState(message: '문제가 발생했습니다'));

      expect(find.text('문제가 발생했습니다'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('icon을 지정하면 해당 아이콘으로 대체된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ErrorState(message: '오프라인', icon: Icons.wifi_off_rounded),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('onRetry 미지정 시 재시도 버튼이 없다', (tester) async {
      await pumpCommonWidget(tester, const ErrorState(message: '문제가 발생했습니다'));

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('onRetry 지정 시 재시도 버튼이 렌더링된다', (tester) async {
      await pumpCommonWidget(
        tester,
        ErrorState(message: '문제가 발생했습니다', onRetry: () {}),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('retry'.tr()), findsOneWidget);
    });
  });

  group('ErrorState 상호작용', () {
    testWidgets('재시도 버튼을 탭하면 onRetry가 호출된다', (tester) async {
      var retried = false;
      await pumpCommonWidget(
        tester,
        ErrorState(message: '문제가 발생했습니다', onRetry: () => retried = true),
      );

      await tester.tap(find.byType(FilledButton));
      expect(retried, true);
    });
  });
}
