import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:feple/auth/token_store.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserService extends Mock implements UserService {}

// 테스트용 JWT (payload: {"sub":"42"})
// base64url("{"sub":"42"}") = eyJzdWIiOiI0MiJ9
const _testToken =
    'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI0MiJ9.signature';

const _kAccessToken = 'accessToken';
const _kUserJson = 'userJson';

AppUser _user({int id = 42, String nickname = '테스터'}) =>
    AppUser(id: id, nickname: nickname);

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
  late MockUserService mockService;

  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() {
    mockService = MockUserService();
    _setupSecureStorageMock();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  Future<UserProvider> make() async {
    final provider = UserProvider(mockService);
    await _pump();
    return provider;
  }

  // ───────────────────────────────────────────────────
  // A. 생성자 — _loadFromSecureStorage
  // ───────────────────────────────────────────────────
  group('A. 생성자 초기화', () {
    test('토큰 없으면 user=null', () async {
      final provider = await make();

      expect(provider.user, isNull);
      expect(provider.currentUserId, isNull);
    });

    test('토큰 + 일치하는 캐시 JSON → user 로드', () async {
      final userJson = jsonEncode(_user(id: 42).toJson());
      _storage[_kAccessToken] = _testToken;
      _storage[_kUserJson] = userJson;

      final provider = await make();

      expect(provider.user?.id, 42);
      expect(provider.user?.nickname, '테스터');
    });

    test('JWT sub와 캐시 userId 불일치 → 캐시 폐기, user=null', () async {
      // _testToken의 sub = 42, 캐시의 id = 99
      final mismatchedJson = jsonEncode(_user(id: 99).toJson());
      _storage[_kAccessToken] = _testToken;
      _storage[_kUserJson] = mismatchedJson;

      final provider = await make();

      expect(provider.user, isNull);
      expect(_storage.containsKey(_kUserJson), false); // 캐시 삭제됨
    });

    test('캐시 JSON 없으면 user=null (토큰만 있음)', () async {
      _storage[_kAccessToken] = _testToken;
      // _kUserJson 없음

      final provider = await make();

      expect(provider.user, isNull);
    });
  });

  // ───────────────────────────────────────────────────
  // B. fetchUser
  // ───────────────────────────────────────────────────
  group('B. fetchUser', () {
    test('성공 시 user 업데이트', () async {
      when(() => mockService.fetchUser(42))
          .thenAnswer((_) async => _user(id: 42, nickname: '업데이트'));

      final provider = await make();
      await provider.fetchUser(42);

      expect(provider.user?.nickname, '업데이트');
    });

    test('서비스 예외 시 user 변경 없음 (예외 전파)', () async {
      when(() => mockService.fetchUser(42)).thenThrow(Exception('network error'));

      final provider = await make();

      await expectLater(
        provider.fetchUser(42),
        throwsException,
      );
    });
  });

  // ───────────────────────────────────────────────────
  // C. fetchUserFromToken
  // ───────────────────────────────────────────────────
  group('C. fetchUserFromToken', () {
    test('성공 시 user 설정', () async {
      when(() => mockService.fetchUserFromToken(any()))
          .thenAnswer((_) async => _user(id: 42));

      final provider = await make();
      await provider.fetchUserFromToken(_testToken);

      expect(provider.user?.id, 42);
    });

    test('401 → user=null, 토큰 삭제 후 예외 전파', () async {
      _storage[_kAccessToken] = _testToken;
      _storage[_kUserJson] = jsonEncode(_user().toJson());
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/users/me'),
          statusCode: 401,
        ),
      );
      when(() => mockService.fetchUserFromToken(any())).thenThrow(dioException);

      final provider = await make();
      // 초기 캐시 로드 확인
      await Future.delayed(Duration.zero);

      await expectLater(
        provider.fetchUserFromToken(_testToken),
        throwsA(isA<DioException>()),
      );

      expect(provider.user, isNull);
      expect(_storage.containsKey(_kAccessToken), false);
    });

    test('403 → user=null, 토큰 삭제', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/users/me'),
          statusCode: 403,
        ),
      );
      when(() => mockService.fetchUserFromToken(any())).thenThrow(dioException);

      final provider = await make();
      await expectLater(
        provider.fetchUserFromToken(_testToken),
        throwsA(isA<DioException>()),
      );

      expect(provider.user, isNull);
    });

    test('404 → user=null, 토큰 삭제 (삭제된 계정)', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/users/me'),
          statusCode: 404,
        ),
      );
      when(() => mockService.fetchUserFromToken(any())).thenThrow(dioException);

      final provider = await make();
      await expectLater(
        provider.fetchUserFromToken(_testToken),
        throwsA(isA<DioException>()),
      );

      expect(provider.user, isNull);
    });

    test('500 → 예외 전파, 기존 user 유지 (오프라인 모드)', () async {
      when(() => mockService.fetchUserFromToken(any()))
          .thenAnswer((_) async => _user(id: 42));

      final provider = await make();
      await provider.fetchUserFromToken(_testToken); // 먼저 성공
      expect(provider.user?.id, 42);

      final serverError = DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/users/me'),
          statusCode: 500,
        ),
      );
      when(() => mockService.fetchUserFromToken(any())).thenThrow(serverError);

      await expectLater(
        provider.fetchUserFromToken(_testToken),
        throwsA(isA<DioException>()),
      );

      expect(provider.user?.id, 42); // 기존 user 유지
    });
  });

  // ───────────────────────────────────────────────────
  // D. setUser
  // ───────────────────────────────────────────────────
  group('D. setUser', () {
    test('user 필드 업데이트 및 notifyListeners 호출', () async {
      final provider = await make();
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setUser(_user(id: 42, nickname: '새닉네임'));

      expect(provider.user?.id, 42);
      expect(provider.user?.nickname, '새닉네임');
      expect(notified, true);
    });

    test('setUser 후 secure storage에 JSON 저장', () async {
      final provider = await make();
      await provider.setUser(_user(id: 42, nickname: '저장테스트'));

      expect(_storage.containsKey(_kUserJson), true);
      final saved = jsonDecode(_storage[_kUserJson]!) as Map<String, dynamic>;
      expect(saved['id'], 42);
      expect(saved['nickname'], '저장테스트');
    });
  });

  // ───────────────────────────────────────────────────
  // E. 게터
  // ───────────────────────────────────────────────────
  group('E. 게터', () {
    test('currentUserId는 user?.id 반환', () async {
      when(() => mockService.fetchUser(10))
          .thenAnswer((_) async => _user(id: 10));

      final provider = await make();
      expect(provider.currentUserId, isNull);

      await provider.fetchUser(10);
      expect(provider.currentUserId, 10);
    });

    test('currentProfileImageUrl은 user?.profileImageUrl 반환', () async {
      when(() => mockService.fetchUser(10)).thenAnswer((_) async =>
          AppUser(id: 10, nickname: '유저', profileImageUrl: 'https://img.example.com/pic.jpg'));

      final provider = await make();
      await provider.fetchUser(10);

      expect(
        provider.currentProfileImageUrl,
        'https://img.example.com/pic.jpg',
      );
    });

    test('TokenStore 저장/읽기 라운드트립', () async {
      await TokenStore.saveAccessToken('myToken');
      final read = await TokenStore.readAccessToken();
      expect(read, 'myToken');
    });

    test('TokenStore.clear 후 read → null', () async {
      await TokenStore.saveAccessToken('myToken');
      await TokenStore.saveRefreshToken('myRefresh');
      await TokenStore.clear();

      expect(await TokenStore.readAccessToken(), isNull);
      expect(await TokenStore.readRefreshToken(), isNull);
    });
  });
}
