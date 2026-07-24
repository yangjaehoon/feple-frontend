import 'package:easy_localization/easy_localization.dart';
import 'package:feple/model/notification_model.dart';

extension NotificationTimeStyle on NotificationModel {
  String get relativeTimeLabel {
    final date = createdAtDate;
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'time_just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'time_minutes_ago'.tr(args: [diff.inMinutes.toString()]);
    }
    if (diff.inHours < 24) {
      return 'time_hours_ago'.tr(args: [diff.inHours.toString()]);
    }
    if (diff.inDays < 7) {
      return 'time_days_ago'.tr(args: [diff.inDays.toString()]);
    }
    if (diff.inDays < 30) {
      return 'time_weeks_ago'.tr(args: [(diff.inDays / 7).floor().toString()]);
    }
    if (diff.inDays < 365) {
      return 'time_months_ago'.tr(
        args: [(diff.inDays / 30).floor().toString()],
      );
    }
    return 'time_years_ago'.tr(args: [(diff.inDays / 365).floor().toString()]);
  }

  String get sectionLabel {
    final date = createdAtDate;
    if (date == null) return 'notif_section_earlier'.tr();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return 'notif_section_today'.tr();
    if (diff == 1) return 'notif_section_yesterday'.tr();
    if (diff < 7) return 'notif_section_this_week'.tr();
    return 'notif_section_earlier'.tr();
  }
}
