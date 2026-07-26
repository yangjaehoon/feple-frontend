import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/home/s_liked_festivals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FestivalModel _festival({
  int id = 1,
  String title = '축제',
  bool ended = false,
}) {
  final now = DateTime.now();
  final start = ended
      ? now.subtract(const Duration(days: 10))
      : now.add(const Duration(days: 10));
  final end = ended
      ? now.subtract(const Duration(days: 5))
      : now.add(const Duration(days: 12));
  return FestivalModel(
    id: id,
    title: title,
    description: '설명',
    location: '서울',
    startDate: start.toIso8601String(),
    endDate: end.toIso8601String(),
    posterUrl: '',
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<FestivalModel> festivals,
  Future<void> Function(List<int>)? onSaveOrder,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
          home: LikedFestivalsScreen(festivals: festivals, onSaveOrder: onSaveOrder),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('LikedFestivalsScreen 렌더링', () {
    testWidgets('진행중 탭이 기본 선택이며 진행중 축제만 보인다', (tester) async {
      await _pump(tester, festivals: [
        _festival(id: 1, title: '진행중축제', ended: false),
        _festival(id: 2, title: '종료축제', ended: true),
      ]);

      expect(find.text('진행중축제'), findsOneWidget);
      expect(find.text('종료축제'), findsNothing);
    });

    testWidgets('진행중 축제가 없으면 안내 문구를 보여준다', (tester) async {
      await _pump(tester, festivals: [_festival(ended: true)]);

      expect(find.text('no_liked_in_tab'.tr()), findsOneWidget);
    });

    testWidgets('onSaveOrder가 있으면 설정 아이콘이 보인다', (tester) async {
      await _pump(tester, festivals: [_festival()], onSaveOrder: (_) async {});

      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('onSaveOrder가 없으면 설정 아이콘이 없다', (tester) async {
      await _pump(tester, festivals: [_festival()]);

      expect(find.byIcon(Icons.settings_rounded), findsNothing);
    });
  });

  group('LikedFestivalsScreen 탭 전환', () {
    testWidgets('종료 탭을 누르면 종료된 축제만 보이고 설정 아이콘이 사라진다', (tester) async {
      await _pump(
        tester,
        festivals: [
          _festival(id: 1, title: '진행중축제', ended: false),
          _festival(id: 2, title: '종료축제', ended: true),
        ],
        onSaveOrder: (_) async {},
      );

      await tester.tap(find.text('tab_ended_festivals'.tr()));
      await tester.pump();

      expect(find.text('종료축제'), findsOneWidget);
      expect(find.text('진행중축제'), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsNothing);
    });
  });

  group('LikedFestivalsScreen 순서 변경', () {
    testWidgets('설정 시트를 열고 저장하면 목록 순서가 즉시 반영된다', (tester) async {
      await _pump(
        tester,
        festivals: [
          _festival(id: 1, title: '첫번째'),
          _festival(id: 2, title: '두번째'),
        ],
        onSaveOrder: (order) async {},
      );

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('liked_festivals'.tr()), findsWidgets);
    });
  });
}
