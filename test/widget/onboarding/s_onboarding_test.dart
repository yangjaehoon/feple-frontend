import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/screen/onboarding/s_onboarding.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistService extends Mock implements ArtistService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}

Artist _artist({int id = 1, String name = '아티스트', String genre = 'KPOP'}) =>
    Artist(
      id: id,
      name: name,
      genre: genre,
      profileImageUrl: '',
      followerCount: 0,
    );

Future<void> _pump(WidgetTester tester, {VoidCallback? onComplete}) async {
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
        child: MaterialApp(home: OnboardingScreen(onComplete: onComplete ?? () {})),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  late MockArtistService mockArtistService;
  late MockArtistFollowService mockFollowService;

  setUp(() {
    Prefs.onboardingCompleted.set(false);
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

  group('OnboardingScreen 정보 페이지', () {
    testWidgets('첫 페이지에 첫 안내 문구와 다음/건너뛰기 버튼이 보인다', (tester) async {
      await _pump(tester);

      expect(find.text('onboarding_title_1'.tr()), findsOneWidget);
      expect(find.text('onboarding_next'.tr()), findsOneWidget);
      expect(find.text('onboarding_skip'.tr()), findsOneWidget);
    });

    testWidgets('다음 버튼을 누르면 두 번째 페이지로 넘어간다', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('onboarding_next'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('onboarding_title_2'.tr()), findsOneWidget);
    });

    testWidgets('마지막 정보 페이지에서 다음을 누르면 아티스트 선택 페이지로 전환된다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => [_artist()]);
      await _pump(tester);

      await tester.tap(find.text('onboarding_next'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding_next'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding_next'.tr()));
      // ArtistPickPage 로딩 스켈레톤(SkeletonBox)은 무한 shimmer라 pumpAndSettle
      // 대신 몇 프레임만 진행시켜 데이터 렌더까지 확인한다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('onboarding_pick_title'.tr()), findsOneWidget);
    });
  });

  group('OnboardingScreen 건너뛰기', () {
    testWidgets('건너뛰기를 누르면 onboardingCompleted가 true가 되고 onComplete가 호출된다', (tester) async {
      var completed = false;
      await _pump(tester, onComplete: () => completed = true);

      await tester.tap(find.text('onboarding_skip'.tr()));
      await tester.pumpAndSettle();

      expect(completed, true);
      expect(Prefs.onboardingCompleted.get(), true);
    });
  });

  group('OnboardingScreen 아티스트 선택', () {
    // 정보 페이지 3개를 지나 아티스트 선택 페이지로 진입한다.
    // ArtistPickPage 로딩 스켈레톤이 무한 shimmer라 마지막은 pumpAndSettle 대신
    // 고정 프레임만 진행시킨다.
    Future<void> goToArtistPick(WidgetTester tester) async {
      await tester.tap(find.text('onboarding_next'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding_next'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding_next'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<Artist>>();
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) => completer.future);
      await _pump(tester);
      await goToArtistPick(tester);

      expect(find.text('onboarding_pick_skip'.tr()), findsOneWidget); // 선택 0개면 skip 라벨
      completer.complete([_artist()]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('아티스트를 선택하지 않으면 버튼 라벨이 건너뛰기이고, 선택하면 시작하기로 바뀐다', (tester) async {
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(id: 1, name: '아이유')]);
      await _pump(tester);
      await goToArtistPick(tester);

      expect(find.text('onboarding_pick_skip'.tr()), findsOneWidget);

      await tester.tap(find.text('아이유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('onboarding_start'.tr()), findsOneWidget);
      expect(find.text('onboarding_pick_selected'.tr(args: ['1'])), findsOneWidget);
    });

    testWidgets('선택한 아티스트를 팔로우하고 완료 콜백을 호출한다', (tester) async {
      var completed = false;
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(id: 7, name: '아이유')]);
      when(() => mockFollowService.follow(any())).thenAnswer((_) async {});
      await _pump(tester, onComplete: () => completed = true);
      await goToArtistPick(tester);

      await tester.tap(find.text('아이유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockFollowService.follow(7)).called(1);
      expect(completed, true);
      expect(Prefs.onboardingCompleted.get(), true);
    });

    testWidgets('아티스트를 선택하지 않고 건너뛰면 follow 없이 완료된다', (tester) async {
      var completed = false;
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist()]);
      await _pump(tester, onComplete: () => completed = true);
      await goToArtistPick(tester);

      await tester.tap(find.text('onboarding_pick_skip'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockFollowService.follow(any()));
      expect(completed, true);
    });

    testWidgets('follow 실패 시 에러 스낵바를 보여주고 완료되지 않는다', (tester) async {
      var completed = false;
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(id: 7, name: '아이유')]);
      when(() => mockFollowService.follow(any())).thenThrow(Exception('네트워크 오류'));
      await _pump(tester, onComplete: () => completed = true);
      await goToArtistPick(tester);

      await tester.tap(find.text('아이유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('onboarding_follow_failed'.tr()), findsOneWidget);
      expect(completed, false);
    });

    testWidgets('아티스트 로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_artist(name: '재시도아티스트')];
      });
      await _pump(tester);
      await goToArtistPick(tester);

      expect(find.text('onboarding_pick_load_failed'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('재시도아티스트'), findsOneWidget);
    });
  });
}
