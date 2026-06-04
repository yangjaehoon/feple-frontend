import 'package:easy_localization/easy_localization.dart';

class PasswordValidator {
  PasswordValidator._();

  static String? validate(String password) {
    final missing = <String>[];
    if (password.length < 8) missing.add('password_min_length'.tr());
    if (password.length > 4096) missing.add('password_max_length'.tr());
    if (!password.contains(RegExp(r'[A-Z]'))) missing.add('password_uppercase'.tr());
    if (!password.contains(RegExp(r'[a-z]'))) missing.add('password_lowercase'.tr());
    if (!password.contains(RegExp(r'[0-9]'))) missing.add('password_digit'.tr());
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) missing.add('password_special'.tr());
    if (missing.isEmpty) return null;
    return missing.join(', ');
  }
}
