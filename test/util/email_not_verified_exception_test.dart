import 'package:feple/common/exception/email_not_verified_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailNotVerifiedException', () {
    test('Exception 타입이다', () {
      expect(EmailNotVerifiedException(), isA<Exception>());
    });

    test('기본값은 인증메일 발송 성공이다', () {
      expect(EmailNotVerifiedException().verificationEmailSent, isTrue);
    });

    test('toString은 클래스 이름과 발송 여부를 반환한다', () {
      expect(
        EmailNotVerifiedException(verificationEmailSent: false).toString(),
        'EmailNotVerifiedException(verificationEmailSent: false)',
      );
    });
  });
}
