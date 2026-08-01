import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/datetime_extension.dart';
import 'package:feple/model/notification_model.dart';

extension NotificationTimeStyle on NotificationModel {
  // 7일 미만은 DateTimeExtension.relativeTime과 동일한 단계(방금 전/분/시간/일)라
  // 그쪽에 위임 — 알림만 7일 이상 지났을 때 날짜 대신 주/개월/년 단위를 추가로 보여줌
  // (게시글·댓글의 relativeTime은 7일 이후 절대 날짜로 표시하는 게 더 적합해 그대로 둠)
  String get relativeTimeLabel {
    final date = createdAtDate;
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 7) return date.relativeTime;
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
