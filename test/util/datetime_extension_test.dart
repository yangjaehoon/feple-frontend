import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/datetime_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('DateTimeExtension.toYMD', () {
    test('yyyy-MM-dd 형식으로 변환한다', () {
      expect(DateTime(2026, 1, 5).toYMD, '2026-01-05');
    });
  });

  group('DateTimeExtension.relativeTime', () {
    test('1분 미만이면 방금 전으로 표시한다', () {
      final now = DateTime.now();
      expect(now.relativeTime, 'time_just_now'.tr());
    });

    test('1시간 미만이면 분 전으로 표시한다', () {
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
      expect(tenMinutesAgo.relativeTime, 'time_minutes_ago'.tr(args: ['10']));
    });

    test('24시간 미만이면 시간 전으로 표시한다', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(threeHoursAgo.relativeTime, 'time_hours_ago'.tr(args: ['3']));
    });

    test('7일 미만이면 일 전으로 표시한다', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(twoDaysAgo.relativeTime, 'time_days_ago'.tr(args: ['2']));
    });

    test('7일 이상이면 날짜로 표시한다', () {
      final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));
      expect(tenDaysAgo.relativeTime, tenDaysAgo.toYMD);
    });
  });
}
