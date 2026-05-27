import 'package:easy_localization/easy_localization.dart';

extension DateTimeExtension on DateTime {
  String get formattedDate => DateFormat('dd/MM/yyyy').format(this);

  String get formattedTime => DateFormat('HH:mm').format(this);

  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /// ISO-8601 날짜 부분만 반환 (yyyy-MM-dd)
  String get toYMD => DateFormat('yyyy-MM-dd').format(this);

  /// 상대 시간 표시 ("방금 전", "3분 전", "2시간 전", "5일 전", 이후엔 날짜)
  String get relativeTime {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'time_just_now'.tr();
    if (diff.inMinutes < 60) return 'time_minutes_ago'.tr(args: [diff.inMinutes.toString()]);
    if (diff.inHours < 24) return 'time_hours_ago'.tr(args: [diff.inHours.toString()]);
    if (diff.inDays < 7) return 'time_days_ago'.tr(args: [diff.inDays.toString()]);
    return toYMD;
  }
}
