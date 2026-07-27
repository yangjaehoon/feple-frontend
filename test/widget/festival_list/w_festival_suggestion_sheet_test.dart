import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_suggestion_sheet.dart';
import 'package:feple/service/festival_suggestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalSuggestionService extends Mock
    implements FestivalSuggestionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFestivalSuggestionService mockService;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockService = MockFestivalSuggestionService();
    if (sl.isRegistered<FestivalSuggestionService>()) {
      sl.unregister<FestivalSuggestionService>();
    }
    sl.registerSingleton<FestivalSuggestionService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalSuggestionService>()) {
      sl.unregister<FestivalSuggestionService>();
    }
  });

  // 실제 앱에서는 f_festival_list.dart가 showAppBottomSheet로 sheet를 연다 —
  // sheet 자체를 화면의 유일한 route로 두면 Navigator.pop(context, true) 후
  // 보여주는 성공 스낵바가 sheet와 함께 사라져버려(호스트 Scaffold가 없으므로)
  // 실제 사용 방식대로 트리거 버튼 + showAppBottomSheet로 열어야 한다.
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
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet(
                    context,
                    builder: (_) => const FestivalSuggestionSheet(),
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

  group('FestivalSuggestionSheet 렌더링', () {
    testWidgets('제목, 입력 필드, 제출 버튼을 보여준다', (tester) async {
      await pump(tester);

      expect(find.text('festival_suggestion_title'.tr()), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(LoadingButton), findsOneWidget);
    });
  });

  group('FestivalSuggestionSheet 유효성 검사', () {
    testWidgets('이름을 입력하지 않고 제출하면 에러 문구를 보여주고 서비스는 호출되지 않는다', (tester) async {
      await pump(tester);

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      button.onPressed!();
      await tester.pump();

      expect(find.text('festival_suggestion_name_required'.tr()), findsOneWidget);
      verifyNever(() => mockService.submit(
            festivalName: any(named: 'festivalName'),
            note: any(named: 'note'),
          ));
    });
  });

  group('FestivalSuggestionSheet 제출', () {
    testWidgets('제출에 성공하면 sheet가 닫히고 성공 스낵바를 보여준다', (tester) async {
      when(() => mockService.submit(
            festivalName: any(named: 'festivalName'),
            note: any(named: 'note'),
          )).thenAnswer((_) async {});

      await pump(tester);
      await tester.enterText(find.byType(TextField).first, '펜타포트');

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      button.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // 시트 닫힘 트랜지션

      verify(() => mockService.submit(festivalName: '펜타포트', note: null))
          .called(1);
      expect(find.byType(FestivalSuggestionSheet), findsNothing);
      expect(find.text('festival_suggestion_success'.tr()), findsOneWidget);
    });

    testWidgets('노트를 입력하면 note와 함께 제출된다', (tester) async {
      when(() => mockService.submit(
            festivalName: any(named: 'festivalName'),
            note: any(named: 'note'),
          )).thenAnswer((_) async {});

      await pump(tester);
      await tester.enterText(find.byType(TextField).first, '펜타포트');
      await tester.enterText(find.byType(TextField).last, '인천에서 열려요');

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      button.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockService.submit(
            festivalName: '펜타포트',
            note: '인천에서 열려요',
          )).called(1);
    });

    testWidgets('409 Conflict면 중복 제안 에러 메시지를 보여주고 sheet는 유지된다', (tester) async {
      when(() => mockService.submit(
            festivalName: any(named: 'festivalName'),
            note: any(named: 'note'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/festival-suggestions'),
        response: Response(
          requestOptions: RequestOptions(path: '/festival-suggestions'),
          statusCode: 409,
        ),
      ));

      await pump(tester);
      await tester.enterText(find.byType(TextField).first, '펜타포트');

      var button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      button.onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('festival_suggestion_duplicate'.tr()), findsOneWidget);
      expect(find.text('festival_suggestion_title'.tr()), findsOneWidget); // sheet 유지
      button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(button.isLoading, false);
    });

    testWidgets('그 외 오류면 일반 실패 메시지를 보여준다', (tester) async {
      when(() => mockService.submit(
            festivalName: any(named: 'festivalName'),
            note: any(named: 'note'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/festival-suggestions'),
        response: Response(
          requestOptions: RequestOptions(path: '/festival-suggestions'),
          statusCode: 500,
        ),
      ));

      await pump(tester);
      await tester.enterText(find.byType(TextField).first, '펜타포트');

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      button.onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('festival_suggestion_failed'.tr()), findsOneWidget);
    });

    testWidgets('제출 중에는 LoadingButton이 로딩 상태가 된다', (tester) async {
      when(() => mockService.submit(
            festivalName: any(named: 'festivalName'),
            note: any(named: 'note'),
          )).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 200)),
      );

      await pump(tester);
      await tester.enterText(find.byType(TextField).first, '펜타포트');

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      button.onPressed!();
      await tester.pump();

      final loading = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(loading.isLoading, true);

      await tester.pumpAndSettle();
    });
  });
}
