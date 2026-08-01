import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_list.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_preview_card.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}

FestivalPreview _festival({int id = 1, String title = '페스티벌'}) => FestivalPreview(
      id: id,
      title: title,
      location: '서울',
      posterUrl: '',
      startDate: DateTime.now().toIso8601String(),
    );

Future<void> _pump(WidgetTester tester, FestivalPreviewProvider provider) async {
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
        child: ChangeNotifierProvider<FestivalPreviewProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(slivers: [FestivalListWidget()]),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late MockFestivalService mockService;

  setUp(() {
    mockService = MockFestivalService();
  });

  group('FestivalListWidget 로딩', () {
    testWidgets('첫 로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<FestivalPreviewPage>();
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) => completer.future);

      await _pump(tester, FestivalPreviewProvider(mockService));

      expect(find.byType(FestivalPreviewCard), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing); // skeleton, not spinner

      completer.complete(const FestivalPreviewPage(items: [], hasMore: false));
      await tester.pump();
      await tester.pump();
    });
  });

  group('FestivalListWidget 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
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
        return FestivalPreviewPage(items: [_festival(title: '복구된 페스티벌')], hasMore: false);
      });

      await _pump(tester, FestivalPreviewProvider(mockService));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('복구된 페스티벌'), findsOneWidget);
    });
  });

  group('FestivalListWidget 빈 목록', () {
    testWidgets('필터 없이 결과가 없으면 기본 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => const FestivalPreviewPage(items: [], hasMore: false));

      await _pump(tester, FestivalPreviewProvider(mockService));
      await tester.pump();
      await tester.pump();

      expect(find.text('no_festival_condition'.tr()), findsOneWidget);
    });

    testWidgets('필터가 적용된 상태에서 결과가 없으면 필터 초기화 안내를 보여준다', (tester) async {
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => const FestivalPreviewPage(items: [], hasMore: false));

      final provider = FestivalPreviewProvider(mockService);
      await _pump(tester, provider);
      await tester.pump();
      await tester.pump();

      provider.toggleGenre('rock');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('no_festival_filter_hint'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      // clearFilters()도 400ms 디바운스 타이머를 새로 예약하므로 완전히 흘려보낸다
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(provider.selectedGenres, isEmpty);
    });
  });

  group('FestivalListWidget 목록', () {
    testWidgets('결과가 있으면 카드 목록을 보여준다', (tester) async {
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => FestivalPreviewPage(items: [
            _festival(id: 1, title: '락 페스티벌'),
            _festival(id: 2, title: '재즈 페스티벌'),
          ], hasMore: false));

      await _pump(tester, FestivalPreviewProvider(mockService));
      await tester.pump();
      await tester.pump();

      expect(find.byType(FestivalPreviewCard), findsNWidgets(2));
      expect(find.text('락 페스티벌'), findsOneWidget);
      expect(find.text('재즈 페스티벌'), findsOneWidget);

      // AnimatedListItem의 stagger 딜레이 Future.delayed를 흘려보내 테스트 종료 시
      // pending timer 어서션에 걸리지 않게 함
      await tester.pumpAndSettle();
    });
  });
}
