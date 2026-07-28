import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/search/w_artist_suggestion_sheet.dart';
import 'package:feple/service/artist_suggestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistSuggestionService extends Mock implements ArtistSuggestionService {}

void main() {
  late MockArtistSuggestionService mockService;

  setUp(() {
    mockService = MockArtistSuggestionService();
    if (sl.isRegistered<ArtistSuggestionService>()) {
      sl.unregister<ArtistSuggestionService>();
    }
    sl.registerSingleton<ArtistSuggestionService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistSuggestionService>()) {
      sl.unregister<ArtistSuggestionService>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
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
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet<bool>(
                    context,
                    builder: (_) => const ArtistSuggestionSheet(),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  group('ArtistSuggestionSheet 유효성 검사', () {
    testWidgets('이름 없이 제출하면 에러가 표시되고 제출되지 않는다', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(LoadingButton, 'artist_suggestion_submit'.tr()));
      await tester.pump();

      expect(find.text('artist_suggestion_name_required'.tr()), findsOneWidget);
      verifyNever(() => mockService.submit(
            artistName: any(named: 'artistName'),
            note: any(named: 'note'),
          ));
    });
  });

  group('ArtistSuggestionSheet 제출', () {
    testWidgets('이름을 입력하고 제출하면 성공 후 닫힌다', (tester) async {
      when(() => mockService.submit(artistName: '새아티스트', note: null))
          .thenAnswer((_) async {});

      await pump(tester);

      await tester.enterText(find.byType(TextField).first, '새아티스트');
      await tester.tap(find.widgetWithText(LoadingButton, 'artist_suggestion_submit'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockService.submit(artistName: '새아티스트', note: null)).called(1);
      expect(find.byType(ArtistSuggestionSheet), findsNothing);
      expect(find.text('artist_suggestion_success'.tr()), findsOneWidget);
    });

    testWidgets('메모를 함께 입력하면 note와 함께 제출된다', (tester) async {
      when(() => mockService.submit(artistName: '새아티스트', note: '메모입니다'))
          .thenAnswer((_) async {});

      await pump(tester);

      await tester.enterText(find.byType(TextField).first, '새아티스트');
      await tester.enterText(find.byType(TextField).last, '메모입니다');
      await tester.tap(find.widgetWithText(LoadingButton, 'artist_suggestion_submit'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockService.submit(artistName: '새아티스트', note: '메모입니다')).called(1);
    });

    testWidgets('중복 제안이면 중복 안내 스낵바를 보여준다', (tester) async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/artist-suggestions'),
        response: Response(
          requestOptions: RequestOptions(path: '/artist-suggestions'),
          statusCode: 409,
        ),
      );
      when(() => mockService.submit(
            artistName: any(named: 'artistName'),
            note: any(named: 'note'),
          )).thenThrow(dioError);

      await pump(tester);

      await tester.enterText(find.byType(TextField).first, '새아티스트');
      await tester.tap(find.widgetWithText(LoadingButton, 'artist_suggestion_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('artist_suggestion_duplicate'.tr()), findsOneWidget);
      expect(find.byType(ArtistSuggestionSheet), findsOneWidget);
    });

    testWidgets('그 외 오류면 실패 스낵바를 보여준다', (tester) async {
      when(() => mockService.submit(
            artistName: any(named: 'artistName'),
            note: any(named: 'note'),
          )).thenThrow(Exception('네트워크 오류'));

      await pump(tester);

      await tester.enterText(find.byType(TextField).first, '새아티스트');
      await tester.tap(find.widgetWithText(LoadingButton, 'artist_suggestion_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('artist_suggestion_failed'.tr()), findsOneWidget);
    });
  });
}
