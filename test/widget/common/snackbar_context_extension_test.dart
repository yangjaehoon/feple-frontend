import 'package:feple/common/dart/extension/snackbar_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      ),
    );
    await tester.pump();
    return captured;
  }

  group('SnackbarContextExtension', () {
    testWidgets('showSnackbar는 메시지를 담은 스낵바를 보여준다', (tester) async {
      final context = await pump(tester);

      context.showSnackbar('안내 메시지');
      await tester.pump();

      expect(find.text('안내 메시지'), findsOneWidget);
    });

    testWidgets('showSuccessSnackbar는 메시지를 담은 스낵바를 보여준다', (tester) async {
      final context = await pump(tester);

      context.showSuccessSnackbar('성공 메시지');
      await tester.pump();

      expect(find.text('성공 메시지'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('showErrorSnackbar는 메시지를 담은 스낵바를 보여준다', (tester) async {
      final context = await pump(tester);

      context.showErrorSnackbar('에러 메시지');
      await tester.pump();

      expect(find.text('에러 메시지'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('showInfoSnackbar는 추가 버튼을 함께 보여줄 수 있다', (tester) async {
      final context = await pump(tester);

      context.showInfoSnackbar('정보 메시지', extraButton: const Text('버튼'));
      await tester.pump();

      expect(find.text('정보 메시지'), findsOneWidget);
      expect(find.text('버튼'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    });

    testWidgets('연속 호출 시 이전 스낵바를 대체한다', (tester) async {
      final context = await pump(tester);

      context.showSnackbar('첫번째');
      await tester.pump();
      context.showSnackbar('두번째');
      await tester.pump();

      expect(find.text('첫번째'), findsNothing);
      expect(find.text('두번째'), findsOneWidget);
    });
  });
}
