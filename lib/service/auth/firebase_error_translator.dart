import 'package:easy_localization/easy_localization.dart';

/// Firebase Auth 에러 코드를 사용자 노출용 i18n 메시지로 변환.
class FirebaseErrorTranslator {
  String translate(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_err_invalid_credential'.tr();
      case 'too-many-requests':
        return 'auth_err_too_many_requests'.tr();
      case 'user-disabled':
        return 'auth_err_account_disabled'.tr();
      case 'email-already-in-use':
        return 'auth_err_email_in_use'.tr();
      case 'weak-password':
        return 'auth_err_weak_password'.tr();
      case 'invalid-email':
        return 'auth_err_invalid_email_format'.tr();
      case 'unknown':
        return 'auth_err_network_error'.tr();
      default:
        return 'auth_err_auth_failed'.tr();
    }
  }
}
