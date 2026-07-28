import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_comment_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required TextEditingController controller,
  bool isSubmitting = false,
  required void Function(bool anonymous) onSubmit,
  String? errorText,
  String? replyToNickname,
  VoidCallback? onCancelReply,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CommentInputBar(
                controller: controller,
                isSubmitting: isSubmitting,
                onSubmit: onSubmit,
                errorText: errorText,
                replyToNickname: replyToNickname,
                onCancelReply: onCancelReply,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CommentInputBar 렌더링', () {
    testWidgets('기본 힌트 문구를 보여준다', (tester) async {
      await _pump(tester, controller: TextEditingController(), onSubmit: (_) {});

      expect(find.text('enter_comment'.tr()), findsOneWidget);
    });

    testWidgets('답글 대상이 있으면 답글 배너와 힌트를 보여준다', (tester) async {
      await _pump(
        tester,
        controller: TextEditingController(),
        onSubmit: (_) {},
        replyToNickname: '홍길동',
      );

      expect(find.textContaining('홍길동'), findsOneWidget);
      expect(find.text('enter_reply'.tr()), findsOneWidget);
    });

    testWidgets('제출 중이면 로딩 인디케이터를 보여준다', (tester) async {
      await _pump(tester, controller: TextEditingController(), isSubmitting: true, onSubmit: (_) {});

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('에러 텍스트를 보여준다', (tester) async {
      await _pump(
        tester,
        controller: TextEditingController(),
        onSubmit: (_) {},
        errorText: '댓글을 입력해주세요',
      );

      expect(find.text('댓글을 입력해주세요'), findsOneWidget);
    });
  });

  group('CommentInputBar 제출', () {
    testWidgets('전송 버튼을 탭하면 onSubmit이 익명 여부와 함께 호출된다', (tester) async {
      bool? submittedAnonymous;
      await _pump(
        tester,
        controller: TextEditingController(text: '댓글'),
        onSubmit: (anonymous) => submittedAnonymous = anonymous,
      );

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(submittedAnonymous, isFalse);
    });

    testWidgets('익명 체크박스를 켜고 전송하면 true로 호출된다', (tester) async {
      bool? submittedAnonymous;
      await _pump(
        tester,
        controller: TextEditingController(text: '댓글'),
        onSubmit: (anonymous) => submittedAnonymous = anonymous,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(submittedAnonymous, isTrue);
    });
  });

  group('CommentInputBar 답글 취소', () {
    testWidgets('취소 버튼을 탭하면 onCancelReply가 호출된다', (tester) async {
      var cancelled = false;
      await _pump(
        tester,
        controller: TextEditingController(),
        onSubmit: (_) {},
        replyToNickname: '홍길동',
        onCancelReply: () => cancelled = true,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
