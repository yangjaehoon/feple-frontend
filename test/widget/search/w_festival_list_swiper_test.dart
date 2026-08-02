import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/screen/main/tab/search/w_festival_list_swiper.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}

FestivalPreview _preview({int id = 1, String title = '축제', bool ended = false}) {
  final now = DateTime.now();
  final start = ended
      ? now.subtract(const Duration(days: 10))
      : now.add(const Duration(days: 10));
  final end = ended
      ? now.subtract(const Duration(days: 5))
      : now.add(const Duration(days: 12));
  return FestivalPreview(
    id: id,
    title: title,
    location: '서울',
    posterUrl: 'https://example.com/$id.png',
    startDate: start.toIso8601String(),
    endDate: end.toIso8601String(),
  );
}

Future<void> _pump(
  WidgetTester tester,
  MockFestivalService mockService, {
  bool settle = true,
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
      child: ChangeNotifierProvider<FestivalPreviewProvider>(
        create: (_) => FestivalPreviewProvider(mockService),
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: FestivalListSwiperWidget()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // Swiper의 autoplay 타이머 때문에 pumpAndSettle은 절대 끝나지 않는다 —
  // 고정 프레임만 진행시켜 비동기 로드가 반영될 시간을 준다.
  if (settle) await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late MockFestivalService mockService;

  setUp(() {
    mockService = MockFestivalService();
  });

  group('FestivalListSwiperWidget 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<FestivalPreviewPage>();
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) => completer.future);

      await _pump(tester, mockService, settle: false);

      expect(find.byType(SkeletonBox), findsWidgets);
      completer.complete(const FestivalPreviewPage(items: [], hasMore: false));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('FestivalListSwiperWidget 빈 상태', () {
    testWidgets('진행중 축제가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => FestivalPreviewPage(items: [_preview(ended: true)], hasMore: false));

      await _pump(tester, mockService);

      expect(find.text('no_upcoming_festivals'.tr()), findsOneWidget);
    });
  });

  group('FestivalListSwiperWidget 첫 페이지가 전부 종료 축제', () {
    testWidgets('hasMore가 true면 다음 페이지를 이어서 가져와 렌더링한다', (tester) async {
      when(() => mockService.fetchPreviews(
            page: 0,
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => FestivalPreviewPage(items: [_preview(ended: true)], hasMore: true));
      when(() => mockService.fetchPreviews(
            page: 1,
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => FestivalPreviewPage(items: [_preview(id: 2, title: '펜타포트')], hasMore: false));

      await _pump(tester, mockService);
      // 자동으로 이어붙인 fetchNext()가 반영되도록 한 프레임 더 진행
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockService.fetchPreviews(
            page: 1,
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(1);
      expect(find.byType(Swiper), findsOneWidget);
    });
  });

  group('FestivalListSwiperWidget 렌더링', () {
    testWidgets('진행중 축제가 있으면 스와이퍼를 렌더링한다', (tester) async {
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => FestivalPreviewPage(
              items: [_preview(title: '서울재즈'), _preview(id: 2, title: '펜타포트')], hasMore: false));

      await _pump(tester, mockService);

      expect(find.byType(Swiper), findsOneWidget);
    });
  });

  group('FestivalListSwiperWidget 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return FestivalPreviewPage(items: [_preview(title: '재시도축제')], hasMore: false);
      });

      await _pump(tester, mockService);

      // card_swiper 내부 제스처 레이어가 tester.tap()의 히트테스트를 가로채므로
      // 캡처한 위젯의 onPressed를 직접 호출해 재시도 로직을 검증한다.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      button.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Swiper), findsOneWidget);
    });
  });
}
