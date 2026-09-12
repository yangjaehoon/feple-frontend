import 'package:feple/service/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firebaseErrorKey', () {
    test('user-not-found/wrong-password/invalid-credential은 동일한 인증 오류 키', () {
      final service = AuthService.instance;

      const expected = 'auth_err_invalid_credential';
      expect(service.firebaseErrorKey('user-not-found'), expected);
      expect(service.firebaseErrorKey('wrong-password'), expected);
      expect(service.firebaseErrorKey('invalid-credential'), expected);
    });

    test('too-many-requests', () {
      expect(
        AuthService.instance.firebaseErrorKey('too-many-requests'),
        'auth_err_too_many_requests',
      );
    });

    test('user-disabled', () {
      expect(
        AuthService.instance.firebaseErrorKey('user-disabled'),
        'auth_err_account_disabled',
      );
    });

    test('email-already-in-use', () {
      expect(
        AuthService.instance.firebaseErrorKey('email-already-in-use'),
        'auth_err_email_in_use',
      );
    });

    test('weak-password', () {
      expect(
        AuthService.instance.firebaseErrorKey('weak-password'),
        'auth_err_weak_password',
      );
    });

    test('invalid-email', () {
      expect(
        AuthService.instance.firebaseErrorKey('invalid-email'),
        'auth_err_invalid_email_format',
      );
    });

    test("unknown 코드는 네트워크 오류 키", () {
      expect(
        AuthService.instance.firebaseErrorKey('unknown'),
        'auth_err_network_error',
      );
    });

    test('매핑되지 않은 코드는 기본 인증 실패 키로 폴백', () {
      const expected = 'auth_err_auth_failed';
      expect(AuthService.instance.firebaseErrorKey('some-unmapped-code'), expected);
      expect(AuthService.instance.firebaseErrorKey(''), expected);
    });
  });
}
