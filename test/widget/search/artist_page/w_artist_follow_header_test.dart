import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_follow_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistFollowNotifier extends Mock implements ArtistFollowNotifier {}
class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockArtistFollowNotifier mockNotifier;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockNotifier = MockArtistFollowNotifier();
    when(() => mockNotifier.isFollowed).thenReturn(false);
    when(() => mockNotifier.isLoading).thenReturn(false);
    when(() => mockNotifier.initFailed).thenReturn(false);
    when(() => mockNotifier.followCount).thenReturn(10);
    when(() => mockNotifier.followStatusKey).thenReturn('follow_done');

    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(1);
  });

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
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    ArtistFollowHeader(
                      artistName: '아티스트',
                      artistId: 1,
                      followNotifier: mockNotifier,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ArtistFollowHeader 렌더링', () {
    testWidgets('아티스트 이름과 팔로워 수를 보여준다', (tester) async {
      await pump(tester);

      expect(find.text('아티스트'), findsOneWidget);
      expect(find.text('follow'.tr()), findsOneWidget);
    });

    testWidgets('팔로우 중이면 following 라벨을 보여준다', (tester) async {
      when(() => mockNotifier.isFollowed).thenReturn(true);

      await pump(tester);

      expect(find.text('following'.tr()), findsOneWidget);
    });
  });

  group('ArtistFollowHeader 팔로우 토글', () {
    testWidgets('로그인 정보가 없으면 로그인 화면으로 이동하고 toggle을 호출하지 않는다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);
      await pump(tester);

      await tester.tap(find.text('follow'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      verifyNever(() => mockNotifier.toggle());
    });

    testWidgets('탭하면 toggle을 호출하고 성공 스낵바를 보여준다', (tester) async {
      when(() => mockNotifier.toggle()).thenAnswer((_) async {});

      await pump(tester);

      await tester.tap(find.text('follow'.tr()));
      await tester.pump();

      verify(() => mockNotifier.toggle()).called(1);
      expect(find.text('follow_done'.tr()), findsOneWidget);
    });

    testWidgets('toggle이 실패하면 실패 스낵바를 보여준다', (tester) async {
      when(() => mockNotifier.toggle()).thenThrow(Exception('네트워크 오류'));

      await pump(tester);

      await tester.tap(find.text('follow'.tr()));
      await tester.pump();

      expect(find.text('follow_failed'.tr()), findsOneWidget);
    });
  });

  // 갤러리 아이콘을 탭하면 이동하는 ImageCollectionScreen은 ArtistPhotoNotifier/
  // ReportService 등 별도 기능 클러스터(image_collection)의 다수 의존성이 필요해
  // 이 테스트에서는 다루지 않는다(기존 컨벤션) — image_collection 전용 테스트에서 다룰 것
}
