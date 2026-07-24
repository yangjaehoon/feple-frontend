import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/open_source_package.dart';
import 'package:feple/screen/opensource/w_opensource_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Package _package({
  String name = '패키지명',
  String description = '패키지 설명',
  List<String> authors = const [],
  String? homepage,
  String? license = '라이센스 내용',
}) =>
    Package(
      name: name,
      description: description,
      authors: authors,
      version: '1.0.0',
      homepage: homepage,
      license: license,
      isMarkdown: false,
      isSdk: false,
      isDirectDependency: true,
    );

Future<void> _pump(WidgetTester tester, Package package) async {
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
        child: MaterialApp(home: Scaffold(body: OpensourceItem(package))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('OpensourceItem 렌더링', () {
    testWidgets('name/description/license가 렌더링된다', (tester) async {
      await _pump(tester, _package(name: '테스트패키지', description: '설명입니다', license: '라이센스 텍스트'));

      expect(find.text('테스트패키지'), findsOneWidget);
      expect(find.text('설명입니다'), findsOneWidget);
      expect(find.text('라이센스 텍스트'), findsOneWidget);
    });

    testWidgets('authors가 비어있으면 authors용 Text가 렌더링되지 않는다', (tester) async {
      await _pump(tester, _package(authors: const []));

      expect(find.byType(Text), findsNWidgets(3)); // name, description, license
    });

    testWidgets('authors가 있으면 콤마로 join되어 보인다', (tester) async {
      await _pump(tester, _package(authors: const ['Alice', 'Bob']));

      expect(find.text('Alice, Bob'), findsOneWidget);
    });

    testWidgets('homepage가 없으면 표시되지 않는다', (tester) async {
      await _pump(tester, _package(homepage: null));

      expect(find.byType(Text), findsNWidgets(3)); // name, description, license
    });

    testWidgets('homepage가 있으면 표시된다', (tester) async {
      await _pump(tester, _package(homepage: 'https://example.com'));

      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('license가 null이면 빈 문자열로 렌더링된다', (tester) async {
      await _pump(tester, _package(license: null));

      expect(find.text(''), findsOneWidget);
    });
  });
}
