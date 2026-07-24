import 'package:easy_localization/easy_localization.dart';

class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;
  // 과도하게 긴 입력으로 인한 해싱 지연/DoS 방지용 상한 — 백엔드 처리 한도와 맞출 것
  static const int maxLength = 4096;
  static const String regexUpper = r'[A-Z]';
  static const String regexLower = r'[a-z]';
  static const String regexDigit = r'[0-9]';
  static const String regexSpecial = r'[!@#$%^&*(),.?":{}|<>]';

  static bool hasMinLength(String pw) => pw.length >= minLength;
  static bool hasUppercase(String pw) => RegExp(regexUpper).hasMatch(pw);
  static bool hasLowercase(String pw) => RegExp(regexLower).hasMatch(pw);
  static bool hasDigit(String pw) => RegExp(regexDigit).hasMatch(pw);
  static bool hasSpecial(String pw) => RegExp(regexSpecial).hasMatch(pw);

  static String? validate(String password) {
    final missing = <String>[];
    if (!hasMinLength(password)) missing.add('password_min_length'.tr());
    if (password.length > maxLength) missing.add('password_max_length'.tr());
    if (!hasUppercase(password)) missing.add('password_uppercase'.tr());
    if (!hasLowercase(password)) missing.add('password_lowercase'.tr());
    if (!hasDigit(password)) missing.add('password_digit'.tr());
    if (!hasSpecial(password)) missing.add('password_special'.tr());
    if (missing.isEmpty) return null;
    return missing.join(', ');
  }
}
