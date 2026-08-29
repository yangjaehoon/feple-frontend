import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/screen/onboarding/s_onboarding.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistService extends Mock implements ArtistService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockFestivalService extends Mock implements FestivalService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}
class MockFestivalCacheService extends Mock implements FestivalCacheService {}

Artist _artist({int id = 1, String name = '아티스트', String genre = 'KPOP'}) =>
    Artist(
      id: id,
      name: name,
      genre: genre,
      profileImageUrl: '',
      followerCount: 0,
    );

FestivalPreview _festival({int id = 1, String title = '페스티벌'}) =>
    FestivalPreview(
      id: id,
      title: title,
      location: '서울',
      posterUrl: '',
      startDate: '2099-01-01',
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
        child: MaterialApp(home: OnboardingScreen(userId: 1, onComplete: onComplete ?? () {})),
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
  late MockFestivalService mockFestivalService;
  late MockFestivalInteractionService mockFestivalInteractionService;
  late MockFestivalCacheService mockFestivalCacheService;

  setUp(() async {
    await Prefs.onboardingCompletedFor(1).set(false);
    await Prefs.pendingHomeForceRefreshFor(1).set(false);
    mockArtistService = MockArtistService();
    mockFollowService = MockArtistFollowService();
    mockFestivalService = MockFestivalService();
    mockFestivalInteractionService = MockFestivalInteractionService();
    mockFestivalCacheService = MockFestivalCacheService();
    when(() => mockFestivalCacheService.clearHome(any())).thenAnswer((_) async {});
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockArtistService);
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    sl.registerSingleton<ArtistFollowService>(mockFollowService);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
    if (sl.isRegistered<FestivalInteractionService>()) sl.unregister<FestivalInteractionService>();
    sl.registerSingleton<FestivalInteractionService>(mockFestivalInteractionService);
    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
    sl.registerSingleton<FestivalCacheService>(mockFestivalCacheService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<FestivalInteractionService>()) sl.unregister<FestivalInteractionService>();
    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
  });

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

  void stubFestivalPreviews(List<FestivalPreview> items) {
    when(() => mockFestivalService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
        )).thenAnswer((_) async => FestivalPreviewPage(items: items, hasMore: false));
  }

  // 아티스트를 선택하지 않고 건너뛰어, _OnboardingScreenState._goToFestivalPick()이
  // 페스티벌 목록을 조회해 페스티벌 선택 여부를 결정하는 지점까지 진행한다.
  // mockArtistService.fetchArtists()/mockFestivalService.fetchPreviews()는
  // 호출부에서 미리 스텁해야 한다.
  Future<void> goToFestivalPick(WidgetTester tester) async {
    await goToArtistPick(tester);
    await tester.tap(find.text('onboarding_pick_skip'.tr()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

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
      expect(Prefs.onboardingCompletedFor(1).get(), true);
    });
  });

  group('OnboardingScreen 아티스트 선택', () {
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

    testWidgets('선택한 아티스트를 팔로우한 뒤 완료 대신 페스티벌 선택 단계로 이동한다', (tester) async {
      var completed = false;
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(id: 7, name: '아이유')]);
      when(() => mockFollowService.follow(any())).thenAnswer((_) async {});
      stubFestivalPreviews([_festival(id: 1), _festival(id: 2), _festival(id: 3)]);
      await _pump(tester, onComplete: () => completed = true);
      await goToArtistPick(tester);

      await tester.tap(find.text('아이유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockFollowService.follow(7)).called(1);
      // 아티스트 선택만으로는 끝나지 않고 페스티벌 선택 페이지가 이어서 나온다.
      expect(find.text('onboarding_festival_pick_title'.tr()), findsOneWidget);
      expect(completed, false);
      expect(Prefs.onboardingCompletedFor(1).get(), false);

      await tester.tap(find.text('onboarding_pick_skip'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(completed, true);
      expect(Prefs.onboardingCompletedFor(1).get(), true);
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

  group('OnboardingScreen 페스티벌 선택 단계 진입 조건', () {
    testWidgets('다가오는 페스티벌이 3개 미만이면 페스티벌 선택 화면을 건너뛰고 완료된다', (tester) async {
      var completed = false;
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => []);
      stubFestivalPreviews([_festival(id: 1), _festival(id: 2)]); // 2개 — 기준 미달
      await _pump(tester, onComplete: () => completed = true);
      await goToFestivalPick(tester);

      expect(find.text('onboarding_festival_pick_title'.tr()), findsNothing);
      expect(completed, true);
      expect(Prefs.onboardingCompletedFor(1).get(), true);
    });

    testWidgets('다가오는 페스티벌이 3개 이상이면 페스티벌 선택 화면이 보인다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => []);
      stubFestivalPreviews([_festival(id: 1), _festival(id: 2), _festival(id: 3)]);
      await _pump(tester);
      await goToFestivalPick(tester);

      expect(find.text('onboarding_festival_pick_title'.tr()), findsOneWidget);
    });

    testWidgets('페스티벌 목록 조회에 실패하면 페스티벌 선택 없이 완료된다', (tester) async {
      var completed = false;
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => []);
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
          )).thenThrow(Exception('네트워크 오류'));
      await _pump(tester, onComplete: () => completed = true);
      await goToFestivalPick(tester);

      expect(find.text('onboarding_festival_pick_title'.tr()), findsNothing);
      expect(completed, true);
    });
  });

  group('OnboardingScreen 페스티벌 선택', () {
    // 아티스트 선택은 건너뛰고, 기준(3개)을 충족하는 페스티벌 목록으로 선택 페이지에 진입한다.
    Future<void> reachFestivalPick(
      WidgetTester tester, {
      List<FestivalPreview>? festivals,
    }) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => []);
      stubFestivalPreviews(
        festivals ?? [_festival(id: 1), _festival(id: 2), _festival(id: 3)],
      );
      await goToFestivalPick(tester);
    }

    testWidgets('페스티벌을 선택하지 않으면 버튼 라벨이 건너뛰기이고, 선택하면 시작하기로 바뀐다', (tester) async {
      await _pump(tester);
      await reachFestivalPick(
        tester,
        festivals: [_festival(id: 1, title: '펜타포트'), _festival(id: 2), _festival(id: 3)],
      );

      expect(find.text('onboarding_pick_skip'.tr()), findsOneWidget);

      await tester.tap(find.text('펜타포트'));
      await tester.pump();

      expect(find.text('onboarding_start'.tr()), findsOneWidget);
      expect(find.text('onboarding_pick_selected'.tr(args: ['1'])), findsOneWidget);
    });

    testWidgets('선택한 페스티벌을 관심 등록하고 완료 콜백을 호출한다', (tester) async {
      var completed = false;
      when(() => mockFestivalInteractionService.toggleLike(any())).thenAnswer((_) async {});
      await _pump(tester, onComplete: () => completed = true);
      await reachFestivalPick(
        tester,
        festivals: [_festival(id: 9, title: '펜타포트'), _festival(id: 2), _festival(id: 3)],
      );

      await tester.tap(find.text('펜타포트'));
      await tester.pump();
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockFestivalInteractionService.toggleLike(9)).called(1);
      expect(completed, true);
      expect(Prefs.onboardingCompletedFor(1).get(), true);
      // 온보딩에서 좋아요한 내용이 홈 첫 진입에 반영되도록 낡은 홈 스냅샷을
      // 지우고 다음 홈 로드를 강제 새로고침으로 표시한다.
      verify(() => mockFestivalCacheService.clearHome(1)).called(1);
      expect(Prefs.pendingHomeForceRefreshFor(1).get(), true);
    });

    testWidgets('페스티벌을 선택하지 않고 건너뛰면 관심 등록 없이 완료된다', (tester) async {
      var completed = false;
      await _pump(tester, onComplete: () => completed = true);
      await reachFestivalPick(tester);

      await tester.tap(find.text('onboarding_pick_skip'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockFestivalInteractionService.toggleLike(any()));
      expect(completed, true);
    });

    testWidgets('관심 등록이 전부 실패하면 에러 스낵바를 보여주고 완료되지 않는다', (tester) async {
      var completed = false;
      when(() => mockFestivalInteractionService.toggleLike(any()))
          .thenThrow(Exception('네트워크 오류'));
      await _pump(tester, onComplete: () => completed = true);
      await reachFestivalPick(
        tester,
        festivals: [_festival(id: 9, title: '펜타포트'), _festival(id: 2), _festival(id: 3)],
      );

      await tester.tap(find.text('펜타포트'));
      await tester.pump();
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('onboarding_festival_like_failed'.tr()), findsOneWidget);
      expect(completed, false);
    });

    testWidgets('일부만 실패해 재시도하면 이미 성공한 항목은 다시 토글되지 않는다', (tester) async {
      var completed = false;
      when(() => mockFestivalInteractionService.toggleLike(1)).thenAnswer((_) async {});
      when(() => mockFestivalInteractionService.toggleLike(2)).thenThrow(Exception('네트워크 오류'));
      await _pump(tester, onComplete: () => completed = true);
      await reachFestivalPick(
        tester,
        festivals: [
          _festival(id: 1, title: '펜타포트'),
          _festival(id: 2, title: '워터밤'),
          _festival(id: 3),
        ],
      );

      await tester.tap(find.text('펜타포트'));
      await tester.pump();
      await tester.tap(find.text('워터밤'));
      await tester.pump();
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('onboarding_festival_like_failed'.tr()), findsOneWidget);
      expect(completed, false);
      verify(() => mockFestivalInteractionService.toggleLike(1)).called(1);
      verify(() => mockFestivalInteractionService.toggleLike(2)).called(1);
      // 성공했던 1번(펜타포트)은 선택 목록에서 빠지고, 실패했던 2번(워터밤)만 남는다.
      expect(find.text('onboarding_pick_selected'.tr(args: ['1'])), findsOneWidget);

      // 에러 스낵바가 화면 하단에 남아있으면 같은 자리의 재시도 버튼 탭을 가로채므로
      // 즉시 제거한다. 카드 포스터가 빈 URL이라 placeholder shimmer가 끝나지 않아
      // pumpAndSettle은 타임아웃나고, 애니메이션 시간을 어림잡아 pump하는 것도
      // 신뢰할 수 없어(스낵바 등장 애니메이션이 다시 트리거될 수 있음) 애니메이션 없이
      // 바로 치우는 removeCurrentSnackBar를 쓴다.
      ScaffoldMessenger.of(
        tester.element(find.text('onboarding_festival_like_failed'.tr())),
      ).removeCurrentSnackBar();
      await tester.pump();

      // 2번도 성공하도록 바꾸고 재시도.
      when(() => mockFestivalInteractionService.toggleLike(2)).thenAnswer((_) async {});
      await tester.tap(find.text('onboarding_start'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // mocktail의 verify()는 이미 검증한 호출을 소비한다 — 위에서 한 번 검증했으므로
      // 여기서는 "그 이후 새로 발생한 호출"만 센다. 1번은 재시도에서 다시 호출되지
      // 않아야 하고(0회), 2번은 재시도로 1회 더 호출돼야 한다.
      verifyNever(() => mockFestivalInteractionService.toggleLike(1));
      verify(() => mockFestivalInteractionService.toggleLike(2)).called(1);
      expect(completed, true);
    });
  });
}
