import 'package:easy_localization/easy_localization.dart';

class EmailValidator {
  EmailValidator._();

  static final RegExp _regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool hasValidFormat(String email) => _regex.hasMatch(email);

  /// 비어있으면 enter_email, 형식이 틀리면 enter_valid_email 메시지 반환, 유효하면 null
  static String? validate(String email) {
    if (email.isEmpty) return 'enter_email'.tr();
    if (!hasValidFormat(email)) return 'enter_valid_email'.tr();
    return null;
  }
}
