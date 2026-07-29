import 'package:feple/common/exception/email_not_verified_exception.dart';
import 'package:feple/model/user_model.dart' as app;
import 'package:feple/service/auth/auth_token_exchanger.dart';
import 'package:feple/service/auth/firebase_email_login_provider.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_firebase_auth.dart';

class MockAuthTokenExchanger extends Mock implements AuthTokenExchanger {}

void main() {
  late FakeFirebaseAuthPlatform fakeAuth;
  late MockAuthTokenExchanger mockExchanger;
  late FirebaseEmailLoginProvider provider;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupFakeFirebaseCore();
    // FirebaseAuth.instance는 앱 이름별로 delegate를 캐싱하므로(_delegatePackingProperty
    // ??=), instance() 자체는 setUpAll에서 한 번만 설정하고 매 테스트에서는 같은 fake
    // 객체의 내부 상태만 초기화해야 캐싱을 우회할 수 있음.
    fakeAuth = FakeFirebaseAuthPlatform();
    FirebaseAuthPlatform.instance = fakeAuth;
  });

  setUp(() {
    fakeAuth.currentUser = null;
    fakeAuth.signOutCallCount = 0;
    fakeAuth.lastPasswordResetEmail = null;
    fakeAuth.onSignInWithEmailAndPassword = null;
    fakeAuth.onCreateUserWithEmailAndPassword = null;
    fakeAuth.onSignInWithCredential = null;
    mockExchanger = MockAuthTokenExchanger();
    provider = FirebaseEmailLoginProvider(mockExchanger);
  });

  group('FirebaseEmailLoginProvider.login', () {
    test('이메일 인증이 완료된 경우 토큰을 교환하고 AppUser를 반환한다', () async {
      final user = FakeUserPlatform(isEmailVerified: true);
      fakeAuth.onSignInWithEmailAndPassword = (email, password) async {
        return FakeUserCredentialPlatform(user);
      };
      when(() => mockExchanger.exchangeFirebaseToken(any()))
          .thenAnswer((_) async => app.AppUser(id: 1, nickname: 'tester'));

      final result = await provider.login('test@example.com', 'password');

      expect(result.id, 1);
      verify(() => mockExchanger.exchangeFirebaseToken('fake-id-token')).called(1);
    });

    test('이메일 인증이 안 된 경우 인증메일을 보내고 예외를 던진다', () async {
      final user = FakeUserPlatform(isEmailVerified: false);
      fakeAuth.onSignInWithEmailAndPassword = (email, password) async {
        return FakeUserCredentialPlatform(user);
      };

      await expectLater(
        provider.login('test@example.com', 'password'),
        throwsA(isA<EmailNotVerifiedException>()),
      );
      expect(user.sendEmailVerificationCallCount, 1);
      verifyNever(() => mockExchanger.exchangeFirebaseToken(any()));
    });
  });

  group('FirebaseEmailLoginProvider.register', () {
    test('성공하면 닉네임을 설정하고 인증메일을 보낸다', () async {
      final user = FakeUserPlatform();
      fakeAuth.onCreateUserWithEmailAndPassword = (email, password) async {
        return FakeUserCredentialPlatform(user);
      };

      await provider.register('test@example.com', 'password', '닉네임');

      expect(user.lastUpdatedProfile, {'displayName': '닉네임'});
      expect(user.sendEmailVerificationCallCount, 1);
      expect(fakeAuth.signOutCallCount, 0);
    });

    test('닉네임 설정 단계에서 실패하면 계정을 롤백(delete + signOut)하고 재전파한다', () async {
      final user = FakeUserPlatform()..updateProfileThrows = true;
      fakeAuth.onCreateUserWithEmailAndPassword = (email, password) async {
        return FakeUserCredentialPlatform(user);
      };

      await expectLater(
        provider.register('test@example.com', 'password', '닉네임'),
        throwsA(isA<Exception>()),
      );
      expect(fakeAuth.signOutCallCount, 1);
    });
  });

  group('FirebaseEmailLoginProvider.resendVerificationEmail', () {
    test('로그인 상태가 아니면 아무것도 하지 않는다', () async {
      fakeAuth.currentUser = null;

      await expectLater(provider.resendVerificationEmail(), completes);
    });

    test('로그인 상태면 인증메일을 재전송한다', () async {
      final user = FakeUserPlatform();
      fakeAuth.currentUser = user;

      await provider.resendVerificationEmail();

      expect(user.sendEmailVerificationCallCount, 1);
    });
  });

  group('FirebaseEmailLoginProvider.cancelUnverifiedSignup', () {
    test('계정을 삭제하고 로그아웃한다', () async {
      final user = FakeUserPlatform();
      fakeAuth.currentUser = user;

      await provider.cancelUnverifiedSignup();

      expect(fakeAuth.signOutCallCount, 1);
    });

    test('삭제가 실패해도 로그아웃은 진행한다', () async {
      final user = FakeUserPlatform(deleteThrows: true);
      fakeAuth.currentUser = user;

      await provider.cancelUnverifiedSignup();

      expect(fakeAuth.signOutCallCount, 1);
    });
  });

  group('FirebaseEmailLoginProvider.completeVerifiedLogin', () {
    test('로그인 상태가 아니면 null을 반환한다', () async {
      fakeAuth.currentUser = null;

      final result = await provider.completeVerifiedLogin();

      expect(result, isNull);
    });

    test('인증이 완료된 상태면 토큰을 교환하고 AppUser를 반환한다', () async {
      final user = FakeUserPlatform(isEmailVerified: true);
      fakeAuth.currentUser = user;
      when(() => mockExchanger.exchangeFirebaseToken(any()))
          .thenAnswer((_) async => app.AppUser(id: 2, nickname: 'tester2'));

      final result = await provider.completeVerifiedLogin();

      expect(result?.id, 2);
      expect(user.reloadCallCount, 1);
    });

    test('reload 후에도 미인증 상태면 null을 반환한다', () async {
      final user = FakeUserPlatform(isEmailVerified: false);
      fakeAuth.currentUser = user;

      final result = await provider.completeVerifiedLogin();

      expect(result, isNull);
    });
  });

  group('FirebaseEmailLoginProvider.sendPasswordReset', () {
    test('비밀번호 재설정 이메일을 요청한다', () async {
      await provider.sendPasswordReset('reset@example.com');

      expect(fakeAuth.lastPasswordResetEmail, 'reset@example.com');
    });
  });
}
