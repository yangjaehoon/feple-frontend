import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/screen/onboarding/s_festival_pick.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}

FestivalPreview _festival({int id = 1, String title = '페스티벌'}) =>
    FestivalPreview(id: id, title: title, location: '서울', posterUrl: '', startDate: '2099-01-01');

Future<void> _pump(WidgetTester tester, {Future<void> Function()? onComplete}) async {
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
          home: FestivalPickScreen(
            onComplete: onComplete ?? () async {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // 카드 포스터가 빈 URL이라 무한 shimmer가 뜬다 — pumpAndSettle 대신 고정 프레임만 진행.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFestivalService mockFestivalService;
  late MockFestivalInteractionService mockFestivalInteractionService;

  setUp(() {
    mockFestivalService = MockFestivalService();
    mockFestivalInteractionService = MockFestivalInteractionService();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
    if (sl.isRegistered<FestivalInteractionService>()) sl.unregister<FestivalInteractionService>();
    sl.registerSingleton<FestivalInteractionService>(mockFestivalInteractionService);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<FestivalInteractionService>()) sl.unregister<FestivalInteractionService>();
  });

  group('FestivalPickScreen 독립 진입 (initialFestivals 없이 직접 조회)', () {
    testWidgets('목록을 직접 조회해 보여준다', (tester) async {
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenAnswer((_) async => FestivalPreviewPage(
            items: [_festival(title: '펜타포트')],
            hasMore: false,
          ));

      await _pump(tester);

      expect(find.text('펜타포트'), findsOneWidget);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenAnswer((_) async => const FestivalPreviewPage(items: [], hasMore: false));

      await _pump(tester);

      expect(find.text('no_upcoming_festivals'.tr()), findsOneWidget);
    });

    testWidgets('조회 실패 시 에러와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return FestivalPreviewPage(items: [_festival(title: '복구된페스티벌')], hasMore: false);
      });

      await _pump(tester);
      expect(find.text('onboarding_festival_pick_load_failed'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('복구된페스티벌'), findsOneWidget);
    });

    testWidgets('선택 후 시작하면 좋아요 등록 후 onComplete가 호출된다', (tester) async {
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenAnswer((_) async => FestivalPreviewPage(
            items: [_festival(id: 3, title: '선택할페스티벌')],
            hasMore: false,
          ));
      when(() => mockFestivalInteractionService.toggleLike(3)).thenAnswer((_) async {});
      var completed = false;

      await _pump(tester, onComplete: () async => completed = true);
      await tester.tap(find.text('선택할페스티벌'));
      await tester.pump();
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockFestivalInteractionService.toggleLike(3)).called(1);
      expect(completed, isTrue);
    });
  });
}
