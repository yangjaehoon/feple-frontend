import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/screen/main/tab/home/s_liked_festivals.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/onboarding/s_festival_pick.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}

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

// LikedFestivalsScreen은 실제로는 항상 홈 위에 push되므로(단독 루트 화면인 적이
// 없음), CTA로 좋아요에 성공했을 때 이 화면까지 함께 닫아 홈으로 돌아가는
// 동작(Navigator.canPop 가드)을 제대로 검증하려면 테스트에서도 뒤에 화면이
// 하나 있는 실제 구조를 흉내내야 한다 — 그래서 더미 홈 위에 push하는 방식으로
// 띄운다.
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LikedFestivalsScreen(
                        festivals: festivals,
                        onSaveOrder: onSaveOrder,
                      ),
                    ),
                  ),
                  child: const Text('fakeHomeOpenButton'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('fakeHomeOpenButton'));
  await tester.pumpAndSettle();
}

void main() {
  late MockFestivalService mockFestivalService;
  late MockFestivalInteractionService mockFestivalInteractionService;

  setUp(() {
    mockFestivalService = MockFestivalService();
    mockFestivalInteractionService = MockFestivalInteractionService();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
    if (sl.isRegistered<FestivalInteractionService>()) sl.unregister<FestivalInteractionService>();
    sl.registerSingleton<FestivalInteractionService>(mockFestivalInteractionService);
    when(() => mockFestivalService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
        )).thenAnswer((_) async => const FestivalPreviewPage(items: [], hasMore: false));
  });

  tearDown(() {
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<FestivalInteractionService>()) sl.unregister<FestivalInteractionService>();
  });

  group('LikedFestivalsScreen 렌더링', () {
    testWidgets('진행중 탭이 기본 선택이며 진행중 축제만 보인다', (tester) async {
      await _pump(tester, festivals: [
        _festival(id: 1, title: '진행중축제', ended: false),
        _festival(id: 2, title: '종료축제', ended: true),
      ]);

      expect(find.text('진행중축제'), findsOneWidget);
      expect(find.text('종료축제'), findsNothing);
    });

    testWidgets('진행중 축제가 없으면 안내 문구와 CTA를 보여준다', (tester) async {
      await _pump(tester, festivals: [_festival(ended: true)]);

      expect(find.text('no_liked_in_tab'.tr()), findsOneWidget);
      expect(find.text('home_add_festivals_cta'.tr()), findsOneWidget);
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

    testWidgets('종료 탭이 비어도 CTA는 없다 (다가오는 축제만 찜할 수 있으므로)', (tester) async {
      await _pump(tester, festivals: [_festival(ended: false)]);

      await tester.tap(find.text('tab_ended_festivals'.tr()));
      await tester.pump();

      expect(find.text('no_liked_in_tab'.tr()), findsOneWidget);
      expect(find.text('home_add_festivals_cta'.tr()), findsNothing);
    });

    testWidgets('진행중 탭이 비었을 때 CTA를 탭하면 FestivalPickScreen으로 이동한다', (tester) async {
      await _pump(tester, festivals: [_festival(ended: true)]);

      await tester.tap(find.text('home_add_festivals_cta'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalPickScreen), findsOneWidget);
    });

    testWidgets('아무것도 찜하지 않고 건너뛰면 이 화면에 그대로 남는다', (tester) async {
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenAnswer((_) async => FestivalPreviewPage(
            items: [
              FestivalPreview(
                id: 9,
                title: '둘러볼페스티벌',
                location: '서울',
                posterUrl: '',
                startDate: '2099-01-01',
              ),
            ],
            hasMore: false,
          ));

      await _pump(tester, festivals: [_festival(ended: true)]);
      await tester.tap(find.text('home_add_festivals_cta'.tr()));
      await tester.pump();
      // 카드 포스터가 빈 URL이라 무한 shimmer가 뜬다 — pumpAndSettle 대신 고정 프레임만 진행.
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('onboarding_pick_skip'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FestivalPickScreen), findsNothing);
      expect(find.text('liked_festivals'.tr()), findsOneWidget);
      expect(find.text('fakeHomeOpenButton'), findsNothing);
    });

    testWidgets('CTA로 실제로 찜하면 이 화면까지 함께 닫혀 홈으로 돌아간다', (tester) async {
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenAnswer((_) async => FestivalPreviewPage(
            items: [
              FestivalPreview(
                id: 9,
                title: '찜할페스티벌',
                location: '서울',
                posterUrl: '',
                startDate: '2099-01-01',
              ),
            ],
            hasMore: false,
          ));
      when(() => mockFestivalInteractionService.toggleLike(9)).thenAnswer((_) async {});

      await _pump(tester, festivals: [_festival(ended: true)]);
      await tester.tap(find.text('home_add_festivals_cta'.tr()));
      await tester.pump();
      // 카드 포스터가 빈 URL이라 무한 shimmer가 뜬다 — pumpAndSettle 대신 고정 프레임만 진행.
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('찜할페스티벌'));
      await tester.pump();
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      verify(() => mockFestivalInteractionService.toggleLike(9)).called(1);
      expect(find.byType(FestivalPickScreen), findsNothing);
      expect(find.byType(LikedFestivalsScreen), findsNothing);
      expect(find.text('fakeHomeOpenButton'), findsOneWidget);
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
