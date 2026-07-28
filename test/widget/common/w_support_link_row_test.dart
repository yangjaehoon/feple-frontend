import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_support_link_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool returnSuccess = true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return returnSuccess;
  }
}

void main() {
  late FakeUrlLauncherPlatform fakeLauncher;

  setUp(() {
    fakeLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  Future<void> pump(WidgetTester tester) async {
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
          child: const MaterialApp(
            home: Scaffold(body: SupportLinkRow()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('SupportLinkRow 렌더링', () {
    testWidgets('안내 문구와 문의 링크를 보여준다', (tester) async {
      await pump(tester);

      expect(find.text('login_trouble'.tr()), findsOneWidget);
      expect(find.text('contact_support'.tr()), findsOneWidget);
    });
  });

  group('SupportLinkRow 탭', () {
    testWidgets('문의하기를 탭하면 링크를 연다', (tester) async {
      await pump(tester);

      await tester.tap(find.text('contact_support'.tr()));
      await tester.pump();

      expect(fakeLauncher.launchedUrls, ['https://open.kakao.com/o/guLhbJki']);
    });

    testWidgets('링크 열기에 실패하면 에러 스낵바를 보여준다', (tester) async {
      fakeLauncher.returnSuccess = false;
      await pump(tester);

      await tester.tap(find.text('contact_support'.tr()));
      await tester.pump();

      expect(find.text('link_open_failed'.tr()), findsOneWidget);
    });
  });
}
