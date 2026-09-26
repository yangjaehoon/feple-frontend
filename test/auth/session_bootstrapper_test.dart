import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:feple/auth/session_bootstrapper.dart';
import 'package:feple/auth/token_store.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}

class MockFestivalCacheService extends Mock implements FestivalCacheService {}

class MockNotificationCountable extends Mock implements NotificationCountable {}

// payload: {"sub":"42"}
const _testToken = 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI0MiJ9.signature';
const _kAccessToken = 'accessToken';
const _kUserJson = 'userJson';

AppUser _user({int id = 42, bool ageVerificationRequired = false}) => AppUser(
      id: id,
      nickname: '테스터',
      ageVerificationRequired: ageVerificationRequired,
    );

Map<String, String> _storage = {};

void _setupSecureStorageMock() {
  _storage = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      final args = call.arguments as Map;
      switch (call.method) {
        case 'read':
          return _storage[args['key'] as String];
        case 'write':
          _storage[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          _storage.remove(args['key'] as String);
          return null;
        case 'deleteAll':
          _storage.clear();
          return null;
        default:
          return null;
      }
    },
  );
}

/// 생성자의 _loadFromSecureStorage 완료 대기
Future<void> _pump() => Future.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserService mockService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() {
    mockService = MockUserService();
    _setupSecureStorageMock();

    final cacheService = MockFestivalCacheService();
    when(() => cacheService.saveHomeArtists(any(), any()))
        .thenAnswer((_) async {});
    when(() => cacheService.saveHomeFestivals(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockService.fetchFollowingArtists(any()))
        .thenAnswer((_) async => []);
    when(() => mockService.fetchLikedFestivals(any()))
        .thenAnswer((_) async => []);

    final countable = MockNotificationCountable();
    when(() => countable.getUnreadCount()).thenAnswer((_) async => 0);

    void replace<T extends Object>(T mock) {
      if (sl.isRegistered<T>()) sl.unregister<T>();
      sl.registerSingleton<T>(mock);
    }

    replace<UserService>(mockService);
    replace<FestivalCacheService>(cacheService);
    replace<NotificationCountable>(countable);
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    sl.registerLazySingleton<NotificationCountNotifier>(
        () => NotificationCountNotifier());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  Future<(UserProvider, SessionBootstrapper)> make() async {
    final provider = UserProvider(mockService);
    await _pump();
    return (provider, SessionBootstrapper(provider));
  }

  test('토큰이 없으면 네트워크 조회를 하지 않는다', () async {
    final (_, bootstrapper) = await make();

    await bootstrapper.resolveIdentity();

    verifyNever(() => mockService.fetchUserFromToken(any()));
  });

  // 스플래시가 붙잡히던 원인 — 이미 아는 유저의 프로필 갱신을 기다렸다.
  test('캐시된 유저가 있으면 네트워크 갱신을 기다리지 않는다', () async {
    _storage[_kAccessToken] = _testToken;
    _storage[_kUserJson] = jsonEncode(_user().toJson());
    final (provider, bootstrapper) = await make();
    final neverCompletes = Completer<AppUser>();
    when(() => mockService.fetchUserFromToken(_testToken))
        .thenAnswer((_) => neverCompletes.future);

    await bootstrapper.resolveIdentity().timeout(
          const Duration(seconds: 1),
          onTimeout: () => fail('갱신을 기다리느라 스플래시가 붙잡혔다'),
        );

    expect(provider.user?.id, 42, reason: '캐시된 신원으로 진입해야 한다');
    verify(() => mockService.fetchUserFromToken(_testToken)).called(1);
  });

  // 게스트 화면을 보여줬다가 뒤늦게 나이확인·온보딩으로 갈아치우면 안 된다.
  test('토큰은 있는데 캐시가 비었으면 갱신을 기다린다', () async {
    _storage[_kAccessToken] = _testToken;
    final (provider, bootstrapper) = await make();
    expect(provider.user, isNull);
    final slow = Completer<AppUser>();
    when(() => mockService.fetchUserFromToken(_testToken))
        .thenAnswer((_) => slow.future);

    var done = false;
    unawaited(bootstrapper.resolveIdentity().then((_) => done = true));
    await _pump();
    expect(done, isFalse, reason: '신원을 모르는 채로 진입하면 안 된다');

    slow.complete(_user());
    await _pump();
    await _pump();
    expect(done, isTrue);
    expect(provider.user?.id, 42);
  });

  test('기다리는 분기에서 401이면 죽은 토큰을 정리한다', () async {
    _storage[_kAccessToken] = _testToken;
    final (provider, bootstrapper) = await make();
    when(() => mockService.fetchUserFromToken(_testToken)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(
            requestOptions: RequestOptions(path: '/users/me'), statusCode: 401),
      ),
    );

    await bootstrapper.resolveIdentity();

    expect(provider.user, isNull);
    expect(await TokenStore.readAccessToken(), isNull);
  });

  // 사용자가 이미 앱을 쓰는 중이므로 안내 없이 게스트로 떨어뜨리면 안 된다.
  test('배경 갱신에서 401이 와도 세션을 끊지 않는다', () async {
    _storage[_kAccessToken] = _testToken;
    _storage[_kUserJson] = jsonEncode(_user().toJson());
    final (provider, bootstrapper) = await make();
    when(() => mockService.fetchUserFromToken(_testToken)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(
            requestOptions: RequestOptions(path: '/users/me'), statusCode: 401),
      ),
    );

    await bootstrapper.resolveIdentity();
    await _pump();

    expect(provider.user?.id, 42, reason: '죽은 토큰은 DioClient가 처리한다');
    expect(await TokenStore.readAccessToken(), _testToken);
  });

  test('배경 갱신에서 예상치 못한 오류가 나도 로그아웃하지 않는다', () async {
    _storage[_kAccessToken] = _testToken;
    _storage[_kUserJson] = jsonEncode(_user().toJson());
    final (provider, bootstrapper) = await make();
    when(() => mockService.fetchUserFromToken(_testToken))
        .thenThrow(FormatException('bad json'));

    await bootstrapper.resolveIdentity();
    await _pump();

    expect(provider.user?.id, 42);
  });

  test('토큰 읽기가 실패해도 던지지 않는다', () async {
    final (_, bootstrapper) = await make();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => throw PlatformException(code: 'storage broken'),
    );

    await expectLater(bootstrapper.resolveIdentity(), completes);
  });
}
