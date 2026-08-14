import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/f_mypage.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_certification.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_diary.dart';
import 'package:feple/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:feple/screen/main/tab/my_page/w_my_song_requests.dart';
import 'package:feple/screen/main/tab/my_page/w_profile.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/screen/settings/s_settings.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_diary_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}
class MockUserActivityService extends Mock implements UserActivityService {}
class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalDiaryService extends Mock implements FestivalDiaryService {}
class MockSongRequestService extends Mock implements SongRequestService {}
class MockNotificationCountable extends Mock implements NotificationCountable {}

const _packageInfoChannel = MethodChannel('dev.fluttercommunity.plus/package_info');

void _setUpPackageInfoMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_packageInfoChannel, (call) async {
    if (call.method == 'getAll') {
      return <String, dynamic>{
        'appName': 'feple',
        'packageName': 'com.example.feple',
        'version': '1.2.3',
        'buildNumber': '42',
        'buildSignature': '',
        'installerStore': null,
      };
    }
    return null;
  });
}

AppUser _user({int id = 1, String nickname = '테스터'}) =>
    AppUser(id: id, nickname: nickname);

UserStats _stats() => const UserStats(
      postCount: 1,
      commentCount: 2,
      certificationCount: 3,
      scrapCount: 4,
      likedPostCount: 5,
    );

void _setupSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  late MockUserService mockUserService;
  late MockUserActivityService mockUserActivityService;
  late MockCertificationService mockCertService;
  late MockFestivalDiaryService mockDiaryService;
  late MockSongRequestService mockSongRequestService;
  late MockNotificationCountable mockNotificationCountable;

  setUp(() {
    _setUpPackageInfoMock();
    mockUserService = MockUserService();
    mockUserActivityService = MockUserActivityService();
    mockCertService = MockCertificationService();
    mockDiaryService = MockFestivalDiaryService();
    mockSongRequestService = MockSongRequestService();
    mockNotificationCountable = MockNotificationCountable();
    _setupSecureStorageMock();

    if (sl.isRegistered<UserActivityService>()) {
      sl.unregister<UserActivityService>();
    }
    sl.registerSingleton<UserActivityService>(mockUserActivityService);
    if (sl.isRegistered<CertificationService>()) {
      sl.unregister<CertificationService>();
    }
    sl.registerSingleton<CertificationService>(mockCertService);
    if (sl.isRegistered<FestivalDiaryService>()) {
      sl.unregister<FestivalDiaryService>();
    }
    sl.registerSingleton<FestivalDiaryService>(mockDiaryService);
    if (sl.isRegistered<SongRequestService>()) {
      sl.unregister<SongRequestService>();
    }
    sl.registerSingleton<SongRequestService>(mockSongRequestService);
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    sl.registerFactory<NotificationCountNotifier>(() => NotificationCountNotifier());
    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);

    when(() => mockUserActivityService.fetchStats(1))
        .thenAnswer((_) async => _stats());
    when(() => mockCertService.getMyCertifications())
        .thenAnswer((_) async => <CertificationModel>[]);
    when(() => mockDiaryService.getMyDiaries())
        .thenAnswer((_) async => <FestivalDiaryModel>[]);
    when(() => mockSongRequestService.fetchAllMyRequests(1))
        .thenAnswer((_) async => <SongRequestModel>[]);
  });

  tearDown(() {
    if (sl.isRegistered<UserActivityService>()) {
      sl.unregister<UserActivityService>();
    }
    if (sl.isRegistered<CertificationService>()) {
      sl.unregister<CertificationService>();
    }
    if (sl.isRegistered<FestivalDiaryService>()) {
      sl.unregister<FestivalDiaryService>();
    }
    if (sl.isRegistered<SongRequestService>()) {
      sl.unregister<SongRequestService>();
    }
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  Future<UserProvider> pump(WidgetTester tester, {bool withUser = true}) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = UserProvider(mockUserService);
    if (withUser) {
      when(() => mockUserService.fetchUser(1)).thenAnswer((_) async => _user());
      await provider.fetchUser(1);
    }

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
          child: ChangeNotifierProvider<UserProvider>.value(
            value: provider,
            child: const MaterialApp(home: MyPageFragment()),
          ),
        ),
      ),
    );
    await tester.pump();
    return provider;
  }

  group('MyPageFragment 로딩', () {
    testWidgets('로그인 유저 정보가 없으면 로딩 스피너를 보여준다', (tester) async {
      await pump(tester, withUser: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ProfileWidget), findsNothing);
    });
  });

  group('MyPageFragment 렌더링', () {
    testWidgets('로그인 유저가 있으면 프로필/통계/인증/신청곡 섹션을 모두 보여준다', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.byType(ProfileWidget), findsOneWidget);
      expect(find.byType(MyPostCommentView), findsOneWidget);
      expect(find.byType(FestivalCertificationWidget), findsOneWidget);
      expect(find.byType(FestivalDiaryWidget), findsOneWidget);
      expect(find.byType(MySongRequestsView), findsOneWidget);
      expect(find.text('테스터'), findsOneWidget);
    });
  });

  group('MyPageFragment 설정', () {
    testWidgets('설정 버튼을 탭하면 설정 화면으로 이동한다', (tester) async {
      await pump(tester);
      await tester.pump();

      await tester.tap(find.byTooltip('settings'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('MyPageFragment 새로고침', () {
    testWidgets('pull-to-refresh 시 통계/인증/신청곡을 모두 다시 불러온다', (tester) async {
      await pump(tester);
      await tester.pump();

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();

      verify(() => mockUserActivityService.fetchStats(1)).called(2);
      verify(() => mockCertService.getMyCertifications()).called(2);
      verify(() => mockDiaryService.getMyDiaries()).called(2);
      verify(() => mockSongRequestService.fetchAllMyRequests(1)).called(2);
    });
  });
}
