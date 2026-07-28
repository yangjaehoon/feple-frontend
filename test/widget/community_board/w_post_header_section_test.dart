import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_post_header_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  String title = '제목',
  String nickname = '작성자',
  bool certified = false,
  bool anonymous = false,
  DateTime? createdAt,
  DateTime? updatedAt,
  VoidCallback? onAuthorTap,
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
            body: PostHeaderSection(
              title: title,
              nickname: nickname,
              certified: certified,
              anonymous: anonymous,
              createdAt: createdAt,
              updatedAt: updatedAt,
              onAuthorTap: onAuthorTap,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PostHeaderSection 렌더링', () {
    testWidgets('제목과 닉네임을 보여준다', (tester) async {
      await _pump(tester, title: '제목입니다', nickname: '홍길동');

      expect(find.text('제목입니다'), findsOneWidget);
      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('수정된 지 10초를 넘겼으면 edited 표시를 보여준다', (tester) async {
      final created = DateTime.now().subtract(const Duration(minutes: 10));
      final updated = created.add(const Duration(minutes: 5));

      await _pump(tester, createdAt: created, updatedAt: updated);

      expect(find.text('edited'.tr()), findsOneWidget);
    });

    testWidgets('생성 후 10초 이내 수정이면 edited 표시가 없다', (tester) async {
      final created = DateTime.now().subtract(const Duration(minutes: 10));
      final updated = created.add(const Duration(seconds: 5));

      await _pump(tester, createdAt: created, updatedAt: updated);

      expect(find.text('edited'.tr()), findsNothing);
    });
  });

  group('PostHeaderSection 익명', () {
    testWidgets('익명 글이면 작성자 프로필을 탭할 수 없다', (tester) async {
      var tapped = false;
      await _pump(tester, anonymous: true, onAuthorTap: () => tapped = true);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('PostHeaderSection 작성자 탭', () {
    testWidgets('작성자를 탭하면 onAuthorTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, onAuthorTap: () => tapped = true);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
