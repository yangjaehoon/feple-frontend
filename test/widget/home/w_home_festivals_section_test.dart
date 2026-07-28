import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/home/w_home_festivals_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FestivalModel _festival({int id = 1, String title = '페스티벌'}) => FestivalModel(
      id: id,
      title: title,
      description: '',
      location: '서울',
      startDate: '2099-08-01',
      endDate: '2099-08-03',
      posterUrl: '',
    );

Future<void> _pump(
  WidgetTester tester, {
  List<FestivalModel>? festivals,
  void Function(FestivalModel)? onTap,
  Object? error,
  VoidCallback? onRetry,
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
            body: HomeFestivalsSection(
              festivals: festivals,
              onTap: onTap ?? (_) {},
              error: error,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HomeFestivalsSection 렌더링', () {
    testWidgets('festivals가 null이면 스켈레톤을 보여준다', (tester) async {
      await _pump(tester, festivals: null);

      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      await _pump(tester, festivals: []);

      expect(find.text('no_liked_festivals'.tr()), findsOneWidget);
    });

    testWidgets('페스티벌 목록을 보여준다', (tester) async {
      await _pump(tester, festivals: [_festival(title: '좋아요한페스티벌')]);

      expect(find.text('좋아요한페스티벌'), findsOneWidget);
    });

    testWidgets('에러가 있으면 에러 상태를 보여준다', (tester) async {
      var retried = false;
      await _pump(
        tester,
        festivals: [_festival()],
        error: Exception('네트워크 오류'),
        onRetry: () => retried = true,
      );

      expect(find.text('페스티벌'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('HomeFestivalsSection 탭', () {
    testWidgets('페스티벌을 탭하면 onTap이 호출된다', (tester) async {
      FestivalModel? tapped;
      await _pump(
        tester,
        festivals: [_festival(id: 9, title: '탭할페스티벌')],
        onTap: (f) => tapped = f,
      );

      await tester.tap(find.text('탭할페스티벌'));
      await tester.pump();

      expect(tapped?.id, 9);
    });
  });
}
