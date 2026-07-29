import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/util/email_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('EmailValidator.hasValidFormat', () {
    test('유효한 이메일 형식이면 true', () {
      expect(EmailValidator.hasValidFormat('test@example.com'), isTrue);
    });

    test('@가 없으면 false', () {
      expect(EmailValidator.hasValidFormat('testexample.com'), isFalse);
    });

    test('도메인에 점이 없으면 false', () {
      expect(EmailValidator.hasValidFormat('test@examplecom'), isFalse);
    });

    test('공백이 포함되면 false', () {
      expect(EmailValidator.hasValidFormat('te st@example.com'), isFalse);
    });
  });

  group('EmailValidator.validate', () {
    test('비어있으면 enter_email 메시지 반환', () {
      expect(EmailValidator.validate(''), 'enter_email'.tr());
    });

    test('형식이 틀리면 enter_valid_email 메시지 반환', () {
      expect(EmailValidator.validate('invalid'), 'enter_valid_email'.tr());
    });

    test('유효하면 null 반환', () {
      expect(EmailValidator.validate('test@example.com'), isNull);
    });
  });
}
