import 'package:feple/common/dart/extension/time_of_day_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeOfDayFormat.toHHmm', () {
    test('시/분을 두 자리로 패딩해 HH:mm 형식으로 반환한다', () {
      expect(const TimeOfDay(hour: 9, minute: 5).toHHmm, '09:05');
    });

    test('두 자리 시/분은 그대로 표시한다', () {
      expect(const TimeOfDay(hour: 23, minute: 45).toHHmm, '23:45');
    });

    test('자정은 00:00으로 표시한다', () {
      expect(const TimeOfDay(hour: 0, minute: 0).toHHmm, '00:00');
    });
  });
}
