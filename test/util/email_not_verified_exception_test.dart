import 'package:feple/common/exception/email_not_verified_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailNotVerifiedException', () {
    test('Exception 타입이다', () {
      expect(EmailNotVerifiedException(), isA<Exception>());
    });

    test('toString은 클래스 이름을 반환한다', () {
      expect(EmailNotVerifiedException().toString(), 'EmailNotVerifiedException');
    });
  });
}
