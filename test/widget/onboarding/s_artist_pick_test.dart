import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/screen/onboarding/s_artist_pick.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistService extends Mock implements ArtistService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}

Artist _artist({int id = 1, String name = '아티스트', String genre = 'KPOP'}) =>
    Artist(id: id, name: name, genre: genre, profileImageUrl: '', followerCount: 0);

// 로딩 스켈레톤이 무한 shimmer라 마지막은 pumpAndSettle 대신 고정 프레임만 진행시킨다.
Future<void> _pump(
  WidgetTester tester, {
  Future<void> Function()? onComplete,
  int? progressDotIndex,
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
          home: ArtistPickScreen(
            onComplete: onComplete ?? () async {},
            progressDotIndex: progressDotIndex,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArtistService mockArtistService;
  late MockArtistFollowService mockFollowService;

  setUp(() {
    mockArtistService = MockArtistService();
    mockFollowService = MockArtistFollowService();
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockArtistService);
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    sl.registerSingleton<ArtistFollowService>(mockFollowService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
  });

  group('ArtistPickScreen 독립 진입', () {
    testWidgets('progressDotIndex가 null이면 정상 렌더링되고 진행 도트가 없다', (tester) async {
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(name: '아이유')]);

      await _pump(tester);

      expect(find.text('아이유'), findsOneWidget);
      expect(find.byKey(const Key('onboardingProgressDots')), findsNothing);
    });

    testWidgets('progressDotIndex가 있으면 진행 도트를 보여준다', (tester) async {
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(name: '아이유')]);

      await _pump(tester, progressDotIndex: 3);

      expect(find.byKey(const Key('onboardingProgressDots')), findsOneWidget);
    });

    testWidgets('아티스트를 선택하고 시작하면 follow 후 onComplete가 호출된다', (tester) async {
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(id: 7, name: '선택할아티스트')]);
      when(() => mockFollowService.follow(7)).thenAnswer((_) async {});
      var completed = false;

      await _pump(tester, onComplete: () async => completed = true);
      await tester.tap(find.text('선택할아티스트'));
      await tester.pump();
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockFollowService.follow(7)).called(1);
      expect(completed, isTrue);
    });

    testWidgets('아무것도 선택하지 않고 건너뛰면 follow 없이 onComplete가 호출된다', (tester) async {
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(name: '건너뛸아티스트')]);
      var completed = false;

      await _pump(tester, onComplete: () async => completed = true);
      await tester.tap(find.text('onboarding_pick_skip'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockFollowService.follow(any()));
      expect(completed, isTrue);
    });
  });
}
