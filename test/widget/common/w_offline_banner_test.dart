import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OfflineBanner 렌더링', () {
    testWidgets('child를 보여준다', (tester) async {
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
              home: Scaffold(body: OfflineBanner(child: Text('본문'))),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('본문'), findsOneWidget);
      // 초기 상태는 온라인으로 가정 — 배너 텍스트는 트리에 존재하지만 화면 밖으로 슬라이드되어 있다.
      expect(find.text('offline_banner'.tr()), findsOneWidget);
    });
  });
}
