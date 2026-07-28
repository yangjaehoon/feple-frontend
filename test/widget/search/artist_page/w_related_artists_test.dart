import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_related_artists.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistService extends Mock implements ArtistService {}

Artist _artist({int id = 1, String name = '아티스트', String genre = 'KPOP'}) => Artist(
      id: id,
      name: name,
      genre: genre,
      profileImageUrl: '',
      followerCount: 0,
    );

void main() {
  late MockArtistService mockService;

  setUp(() {
    mockService = MockArtistService();
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
  });

  Future<void> pump(WidgetTester tester, {GlobalKey<RelatedArtistsState>? key}) async {
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
            home: Scaffold(body: RelatedArtists(key: key, artistId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('RelatedArtists 렌더링', () {
    testWidgets('연관 아티스트를 보여준다', (tester) async {
      when(() => mockService.fetchRelatedArtists(1))
          .thenAnswer((_) async => [_artist(name: '연관아티스트')]);

      await pump(tester);
      await tester.pump();

      expect(find.text('related_artists'.tr()), findsOneWidget);
      expect(find.text('연관아티스트'), findsOneWidget);
    });

    testWidgets('연관 아티스트가 없으면 아무것도 보여주지 않는다', (tester) async {
      when(() => mockService.fetchRelatedArtists(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('related_artists'.tr()), findsNothing);
    });

    testWidgets('로드 실패 시 아무것도 보여주지 않는다', (tester) async {
      when(() => mockService.fetchRelatedArtists(1))
          .thenAnswer((_) async => throw Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();

      expect(find.text('related_artists'.tr()), findsNothing);
    });
  });

  // 아티스트 카드 탭 시 이동하는 ArtistScreen은 ArtistScheduleService/PostService/
  // SongService/ArtistFollowService 등 다수의 sl<> 의존성이 필요한 무거운 화면이라
  // 다른 위젯의 네비게이션 테스트에서는 깊이 들어가지 않는다(기존 컨벤션)

  group('RelatedArtists 새로고침', () {
    testWidgets('refresh를 호출하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchRelatedArtists(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });
      final key = GlobalKey<RelatedArtistsState>();

      await pump(tester, key: key);
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
