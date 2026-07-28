import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  String title = '섹션 제목',
  VoidCallback? onExpand,
  Widget? trailing,
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
            body: HomeSectionHeader(title: title, onExpand: onExpand, trailing: trailing),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HomeSectionHeader 렌더링', () {
    testWidgets('제목을 보여준다', (tester) async {
      await _pump(tester, title: '인기 게시판');

      expect(find.text('인기 게시판'), findsOneWidget);
    });

    testWidgets('onExpand이 있으면 화살표 아이콘을 보여준다', (tester) async {
      await _pump(tester, onExpand: () {});

      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('onExpand이 없고 trailing이 있으면 trailing을 보여준다', (tester) async {
      await _pump(tester, trailing: const Icon(Icons.settings));

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
    });
  });

  group('HomeSectionHeader 탭', () {
    testWidgets('화살표를 탭하면 onExpand이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, onExpand: () => tapped = true);

      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
