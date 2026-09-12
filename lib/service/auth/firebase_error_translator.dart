/// Firebase Auth 에러 코드를 i18n 키로 변환. 번역은 호출부(위젯)에서 `.tr()`로 수행한다.
class FirebaseErrorTranslator {
  String translate(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_err_invalid_credential';
      case 'too-many-requests':
        return 'auth_err_too_many_requests';
      case 'user-disabled':
        return 'auth_err_account_disabled';
      case 'email-already-in-use':
        return 'auth_err_email_in_use';
      case 'weak-password':
        return 'auth_err_weak_password';
      case 'invalid-email':
        return 'auth_err_invalid_email_format';
      case 'unknown':
        return 'auth_err_network_error';
      default:
        return 'auth_err_auth_failed';
    }
  }
}
