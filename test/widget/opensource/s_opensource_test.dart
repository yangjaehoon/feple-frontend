import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/opensource/s_opensource.dart';
import 'package:feple/screen/opensource/w_opensource_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// assets/json/licenses.json 로딩은 실제 플랫폼 채널을 거쳐 rootBundle이
// 파일을 읽는다 — fake-async 테스트 존 안에서는 완료되지 않고 무한 대기하므로
// tester.runAsync()로 실제 이벤트 루프를 잠깐 빌려와야 한다.
Future<void> _pumpAndLoad(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  await tester.runAsync(() async {
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
          child: const MaterialApp(home: OpensourceScreen()),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}

void main() {
  group('OpensourceScreen', () {
    testWidgets('타이틀과 패키지 목록이 렌더링된다', (tester) async {
      await _pumpAndLoad(tester);

      expect(find.text('opensource'.tr()), findsOneWidget);
      expect(find.byType(OpensourceItem), findsWidgets);
      // licenses.json의 첫 패키지(생성 순서상 안정적으로 맨 앞에 위치)
      expect(find.text('_fe_analyzer_shared'), findsOneWidget);
    });
  });
}
