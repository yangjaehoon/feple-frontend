import 'package:easy_localization/easy_localization.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/notification/notification_time_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

NotificationModel _notification({DateTime? createdAt}) => NotificationModel(
      id: 1,
      type: NotificationType.newComment,
      title: '제목',
      body: '내용',
      read: false,
      createdAt: createdAt?.toIso8601String(),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('relativeTimeLabel', () {
    test('createdAt이 없으면 빈 문자열을 반환한다', () {
      expect(_notification().relativeTimeLabel, '');
    });

    test('1분 미만이면 방금 전을 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(seconds: 30)));
      expect(n.relativeTimeLabel, 'time_just_now'.tr());
    });

    test('분 단위 경과를 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(minutes: 10)));
      expect(n.relativeTimeLabel, 'time_minutes_ago'.tr(args: ['10']));
    });

    test('시간 단위 경과를 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(hours: 5)));
      expect(n.relativeTimeLabel, 'time_hours_ago'.tr(args: ['5']));
    });

    test('일 단위 경과를 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(days: 3)));
      expect(n.relativeTimeLabel, 'time_days_ago'.tr(args: ['3']));
    });
  });

  group('sectionLabel', () {
    test('createdAt이 없으면 earlier 섹션을 반환한다', () {
      expect(_notification().sectionLabel, 'notif_section_earlier'.tr());
    });

    test('오늘이면 today 섹션을 반환한다', () {
      final n = _notification(createdAt: DateTime.now());
      expect(n.sectionLabel, 'notif_section_today'.tr());
    });

    test('어제면 yesterday 섹션을 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(days: 1)));
      expect(n.sectionLabel, 'notif_section_yesterday'.tr());
    });

    test('이번 주(2~6일 전)면 this_week 섹션을 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(days: 3)));
      expect(n.sectionLabel, 'notif_section_this_week'.tr());
    });

    test('일주일 이상 전이면 earlier 섹션을 반환한다', () {
      final n = _notification(createdAt: DateTime.now().subtract(const Duration(days: 10)));
      expect(n.sectionLabel, 'notif_section_earlier'.tr());
    });
  });
}
