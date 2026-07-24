import 'package:easy_localization/easy_localization.dart';
import 'package:feple/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // EasyLocalizationController가 로케일 저장에 shared_preferences를 사용한다.
    // 목킹하지 않으면 플랫폼 채널 응답을 무한 대기해 테스트가 타임아웃난다.
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLocalized(WidgetTester tester) async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: const SizedBox(),
    ));
    await tester.pump();
  }

  group('firebaseErrorMessage', () {
    testWidgets('user-not-found/wrong-password/invalid-credential은 동일한 인증 오류 메시지',
        (tester) async {
      await pumpLocalized(tester);
      final service = AuthService.instance;

      final expected = 'auth_err_invalid_credential'.tr();
      expect(service.firebaseErrorMessage('user-not-found'), expected);
      expect(service.firebaseErrorMessage('wrong-password'), expected);
      expect(service.firebaseErrorMessage('invalid-credential'), expected);
    });

    testWidgets('too-many-requests', (tester) async {
      await pumpLocalized(tester);
      expect(
        AuthService.instance.firebaseErrorMessage('too-many-requests'),
        'auth_err_too_many_requests'.tr(),
      );
    });

    testWidgets('user-disabled', (tester) async {
      await pumpLocalized(tester);
      expect(
        AuthService.instance.firebaseErrorMessage('user-disabled'),
        'auth_err_account_disabled'.tr(),
      );
    });

    testWidgets('email-already-in-use', (tester) async {
      await pumpLocalized(tester);
      expect(
        AuthService.instance.firebaseErrorMessage('email-already-in-use'),
        'auth_err_email_in_use'.tr(),
      );
    });

    testWidgets('weak-password', (tester) async {
      await pumpLocalized(tester);
      expect(
        AuthService.instance.firebaseErrorMessage('weak-password'),
        'auth_err_weak_password'.tr(),
      );
    });

    testWidgets('invalid-email', (tester) async {
      await pumpLocalized(tester);
      expect(
        AuthService.instance.firebaseErrorMessage('invalid-email'),
        'auth_err_invalid_email_format'.tr(),
      );
    });

    testWidgets("unknown 코드는 네트워크 오류 메시지", (tester) async {
      await pumpLocalized(tester);
      expect(
        AuthService.instance.firebaseErrorMessage('unknown'),
        'auth_err_network_error'.tr(),
      );
    });

    testWidgets('매핑되지 않은 코드는 기본 인증 실패 메시지로 폴백', (tester) async {
      await pumpLocalized(tester);
      final expected = 'auth_err_auth_failed'.tr();
      expect(AuthService.instance.firebaseErrorMessage('some-unmapped-code'), expected);
      expect(AuthService.instance.firebaseErrorMessage(''), expected);
    });
  });
}
