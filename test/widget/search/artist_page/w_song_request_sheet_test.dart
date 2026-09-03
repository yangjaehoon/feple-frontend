import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_request_sheet.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSongRequestService extends Mock implements SongRequestService {}
class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockSongRequestService mockService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockService = MockSongRequestService();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(1);
    if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
    sl.registerSingleton<SongRequestService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
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
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            // 실제 사용처(showAppBottomSheet)와 동일하게 모달 바텀시트로 열어야
            // 트리거 화면의 ScaffoldMessenger가 남아있어 에러 스낵바가 보인다.
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showAppBottomSheet<bool>(
                      context,
                      isDismissible: false,
                      enableDrag: false,
                      builder: (_) => const SongRequestSheet(
                        artistId: 1,
                        artistName: '아티스트',
                      ),
                    ),
                    child: const Text('열기'),
                  ),
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

  group('SongRequestSheet 유효성 검사', () {
    testWidgets('제목을 입력하지 않으면 에러가 표시되고 제출되지 않는다', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(LoadingButton, 'song_request_submit'.tr()));
      await tester.pump();

      expect(find.text('song_request_title_required'.tr()), findsOneWidget);
      verifyNever(() => mockService.submit(
            artistId: any(named: 'artistId'),
            songTitle: any(named: 'songTitle'),
            youtubeUrl: any(named: 'youtubeUrl'),
          ));
    });

    testWidgets('유효하지 않은 URL이면 에러가 표시된다', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_song_title_hint'.tr()),
        '노래 제목',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_youtube_url_hint'.tr()),
        'https://evil.example.com',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'song_request_submit'.tr()));
      await tester.pump();

      expect(find.text('song_request_invalid_url'.tr()), findsOneWidget);
    });

    testWidgets('로그인 정보가 없으면 안내 스낵바를 보여주고 제출하지 않는다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);
      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_song_title_hint'.tr()),
        '노래 제목',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'song_request_submit'.tr()));
      await tester.pump();

      expect(find.text('login_required'.tr()), findsOneWidget);
      verifyNever(() => mockService.submit(
            artistId: any(named: 'artistId'),
            songTitle: any(named: 'songTitle'),
            youtubeUrl: any(named: 'youtubeUrl'),
          ));
    });
  });

  group('SongRequestSheet 제출', () {
    testWidgets('제목만 입력하고 제출하면 성공 후 닫힌다', (tester) async {
      when(() => mockService.submit(
            artistId: 1,
            songTitle: '노래 제목',
            youtubeUrl: null,
          )).thenAnswer((_) async {});

      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_song_title_hint'.tr()),
        '노래 제목',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'song_request_submit'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockService.submit(
            artistId: 1,
            songTitle: '노래 제목',
            youtubeUrl: null,
          )).called(1);
      expect(find.byType(SongRequestSheet), findsNothing);
    });

    testWidgets('중복 신청 오류면 중복 안내 스낵바를 보여준다', (tester) async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/artists/1/song-requests'),
        response: Response(
          requestOptions: RequestOptions(path: '/artists/1/song-requests'),
          statusCode: 409,
        ),
      );
      when(() => mockService.submit(
            artistId: any(named: 'artistId'),
            songTitle: any(named: 'songTitle'),
            youtubeUrl: any(named: 'youtubeUrl'),
          )).thenThrow(dioError);

      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_song_title_hint'.tr()),
        '노래 제목',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'song_request_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('song_request_duplicate'.tr()), findsOneWidget);
      expect(find.byType(SongRequestSheet), findsOneWidget);
    });

    testWidgets('그 외 오류면 실패 스낵바를 보여준다', (tester) async {
      when(() => mockService.submit(
            artistId: any(named: 'artistId'),
            songTitle: any(named: 'songTitle'),
            youtubeUrl: any(named: 'youtubeUrl'),
          )).thenThrow(Exception('네트워크 오류'));

      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_song_title_hint'.tr()),
        '노래 제목',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'song_request_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('song_request_failed'.tr()), findsOneWidget);
    });
  });

  group('SongRequestSheet 닫기', () {
    testWidgets('입력한 내용이 없으면 확인 없이 바로 닫힌다', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SongRequestSheet), findsNothing);
    });

    testWidgets('입력한 내용이 있으면 확인 다이얼로그를 보여준다', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'song_request_song_title_hint'.tr()),
        '작성 중',
      );
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('discard_changes'.tr()), findsOneWidget);
      expect(find.byType(SongRequestSheet), findsOneWidget);
    });
  });
}
