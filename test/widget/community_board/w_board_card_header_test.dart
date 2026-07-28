import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, {required VoidCallback onTap}) async {
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
            body: BoardCardHeader(
              icon: Icons.forum_rounded,
              title: '자유 게시판',
              headerColor: Colors.blue,
              onTap: onTap,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BoardCardHeader 렌더링', () {
    testWidgets('아이콘, 제목, 더보기 문구를 보여준다', (tester) async {
      await _pump(tester, onTap: () {});

      expect(find.text('자유 게시판'), findsOneWidget);
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
      expect(find.text('see_more'.tr()), findsOneWidget);
    });
  });

  group('BoardCardHeader 탭', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, onTap: () => tapped = true);

      await tester.tap(find.text('자유 게시판'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
