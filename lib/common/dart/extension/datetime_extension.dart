

import 'package:easy_localization/easy_localization.dart';

extension DateTimeExtension on DateTime {
  String get formattedDate => DateFormat('dd/MM/yyyy').format(this);

  String get formattedTime => DateFormat('HH:mm').format(this);

  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /// ISO-8601 날짜 부분만 반환 (yyyy-MM-dd)
  String get toYMD => DateFormat('yyyy-MM-dd').format(this);
}
