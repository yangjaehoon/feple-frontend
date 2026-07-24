import 'package:feple/common/common.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme_app.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/screen/opensource/s_opensource.dart';
import 'package:feple/screen/settings/s_blocked_users.dart';
import 'package:feple/screen/settings/s_notification_settings.dart';
import 'package:feple/screen/settings/s_settings.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/notification_preference_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserProvider extends Mock implements UserProvider {}
class MockFestivalCacheService extends Mock implements FestivalCacheService {}
class MockBlockService extends Mock implements BlockService {}
class MockNotificationPreferenceService extends Mock
    implements NotificationPreferenceService {}
class MockUserService extends Mock implements UserService {}
class MockArtistService extends Mock implements ArtistService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}

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

void _tearDownPackageInfoMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_packageInfoChannel, null);
}

Future<void> _pump(WidgetTester tester, MockUserProvider userProvider) async {
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
        value: userProvider,
        child: CustomThemeApp(
          child: Builder(
            builder: (context) => MaterialApp(
              theme: context.themeType.themeData,
              home: const SettingsScreen(),
            ),
          ),
        ),
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

  late MockUserProvider mockUserProvider;

  setUp(() {
    _setUpPackageInfoMock();
    mockUserProvider = MockUserProvider();
    // 테스트 간 Prefs 상태 오염 방지 — 기본값(true)으로 리셋
    Prefs.showCurrentTimeLine.set(true);

    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
    sl.registerSingleton<FestivalCacheService>(MockFestivalCacheService());
    if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
    sl.registerSingleton<BlockService>(MockBlockService());
    if (sl.isRegistered<NotificationPreferenceService>()) {
      sl.unregister<NotificationPreferenceService>();
    }
    sl.registerSingleton<NotificationPreferenceService>(MockNotificationPreferenceService());
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    sl.registerSingleton<UserService>(MockUserService());
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(MockArtistService());
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    sl.registerSingleton<ArtistFollowService>(MockArtistFollowService());
  });

  tearDown(() {
    _tearDownPackageInfoMock();
    for (final unregister in [
      () => sl.unregister<FestivalCacheService>(),
      () => sl.unregister<BlockService>(),
      () => sl.unregister<NotificationPreferenceService>(),
      () => sl.unregister<UserService>(),
      () => sl.unregister<ArtistService>(),
      () => sl.unregister<ArtistFollowService>(),
    ]) {
      try {
        unregister();
      } catch (_) {}
    }
  });

  group('SettingsScreen 렌더링', () {
    testWidgets('앱 버전과 각 섹션이 렌더링된다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      expect(find.text('v1.2.3'), findsOneWidget);
      expect(find.text('edit_profile'.tr()), findsOneWidget);
      expect(find.text('blocked_users'.tr()), findsOneWidget);
      expect(find.text('logout'.tr()), findsOneWidget);
      expect(find.text('delete_account'.tr()), findsOneWidget);
      expect(find.text('dark_mode'.tr()), findsOneWidget);
      expect(find.text('clear_cache'.tr()), findsOneWidget);
      expect(find.text('customer_service'.tr()), findsOneWidget);
      expect(find.text('opensource'.tr()), findsOneWidget);
    });

    testWidgets('디버그 모드에서는 DEV 섹션이 보인다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      expect(find.text('onboarding_replay'.tr()), findsOneWidget);
    });

    testWidgets('다크모드 스위치는 현재 테마를 반영한다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      final darkSwitch = tester.widget<Switch>(find.byType(Switch).first);
      expect(darkSwitch.value, false); // CustomTheme.light 시작
    });

    testWidgets('현재시간선 스위치는 Prefs 값을 반영한다', (tester) async {
      Prefs.showCurrentTimeLine.set(false);
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[1].value, false);
    });
  });

  group('SettingsScreen 토글', () {
    testWidgets('현재시간선 스위치를 탭하면 Prefs 값이 바뀐다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();

      expect(Prefs.showCurrentTimeLine.get(), false);
    });

    testWidgets('다크모드 스위치를 탭하면 테마가 전환된다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final darkSwitch = tester.widget<Switch>(find.byType(Switch).first);
      expect(darkSwitch.value, true);
    });
  });

  group('SettingsScreen 네비게이션', () {
    testWidgets('내 프로필 수정 탭하면 EditProfileWidget으로 이동한다', (tester) async {
      when(() => mockUserProvider.user).thenReturn(null);
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('edit_profile'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileWidget), findsOneWidget);
    });

    testWidgets('차단 관리 탭하면 BlockedUsersScreen으로 이동한다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('blocked_users'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedUsersScreen), findsOneWidget);
    });

    testWidgets('알림 설정 탭하면 NotificationSettingsScreen으로 이동한다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('notif_settings'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });

    testWidgets('오픈소스 라이센스 탭하면 OpensourceScreen으로 이동한다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('opensource'.tr()));
      // OpensourceScreen이 licenses.json을 실제 로드하려 해 pumpAndSettle이
      // 멈추지 않으므로, SlideRoute 애니메이션만 진행시켜 화면 진입을 확인한다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(OpensourceScreen), findsOneWidget);
    });
  });

  group('SettingsScreen 로그아웃', () {
    testWidgets('로그아웃 탭하면 확인 다이얼로그가 뜨고, 취소하면 유지된다', (tester) async {
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('logout'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('logout_confirm'.tr()), findsOneWidget);

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      verifyNever(() => mockUserProvider.logout());
    });

    testWidgets('로그아웃 확인하면 UserProvider.logout()이 호출된다', (tester) async {
      when(() => mockUserProvider.logout()).thenAnswer((_) async {});
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('logout'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('logout'.tr()).last);
      await tester.pumpAndSettle();

      verify(() => mockUserProvider.logout()).called(1);
    });
  });

  group('SettingsScreen 회원탈퇴', () {
    testWidgets('회원탈퇴 확인하면 UserProvider.deleteAccount()가 호출된다', (tester) async {
      when(() => mockUserProvider.deleteAccount()).thenAnswer((_) async {});
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('delete_account'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete_account'.tr()).last);
      await tester.pumpAndSettle();

      verify(() => mockUserProvider.deleteAccount()).called(1);
    });

    testWidgets('회원탈퇴 실패 시 에러 스낵바를 보여준다', (tester) async {
      when(() => mockUserProvider.deleteAccount()).thenThrow(Exception('실패'));
      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('delete_account'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete_account'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.text('delete_account_error'.tr()), findsOneWidget);
    });
  });
}
