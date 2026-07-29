import 'package:easy_localization/easy_localization.dart';
import 'package:feple/service/auth/firebase_error_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FirebaseErrorTranslator translator;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    translator = FirebaseErrorTranslator();
  });

  group('FirebaseErrorTranslator.translate', () {
    test('user-not-found은 invalid_credential 메시지를 반환한다', () {
      expect(translator.translate('user-not-found'), 'auth_err_invalid_credential'.tr());
    });

    test('wrong-password는 invalid_credential 메시지를 반환한다', () {
      expect(translator.translate('wrong-password'), 'auth_err_invalid_credential'.tr());
    });

    test('invalid-credential은 invalid_credential 메시지를 반환한다', () {
      expect(translator.translate('invalid-credential'), 'auth_err_invalid_credential'.tr());
    });

    test('too-many-requests는 too_many_requests 메시지를 반환한다', () {
      expect(translator.translate('too-many-requests'), 'auth_err_too_many_requests'.tr());
    });

    test('user-disabled는 account_disabled 메시지를 반환한다', () {
      expect(translator.translate('user-disabled'), 'auth_err_account_disabled'.tr());
    });

    test('email-already-in-use는 email_in_use 메시지를 반환한다', () {
      expect(translator.translate('email-already-in-use'), 'auth_err_email_in_use'.tr());
    });

    test('weak-password는 weak_password 메시지를 반환한다', () {
      expect(translator.translate('weak-password'), 'auth_err_weak_password'.tr());
    });

    test('invalid-email은 invalid_email_format 메시지를 반환한다', () {
      expect(translator.translate('invalid-email'), 'auth_err_invalid_email_format'.tr());
    });

    test('unknown은 network_error 메시지를 반환한다', () {
      expect(translator.translate('unknown'), 'auth_err_network_error'.tr());
    });

    test('알 수 없는 코드는 auth_failed 메시지를 반환한다', () {
      expect(translator.translate('some-other-code'), 'auth_err_auth_failed'.tr());
    });
  });
}
