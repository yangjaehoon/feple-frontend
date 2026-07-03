import 'package:feple/common/util/festival_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isFestivalEnded', () {
    test('null이면 false', () {
      expect(isFestivalEnded(null), false);
    });

    test('빈 문자열이면 false', () {
      expect(isFestivalEnded(''), false);
    });

    test('잘못된 날짜 형식이면 false', () {
      expect(isFestivalEnded('not-a-date'), false);
      expect(isFestivalEnded('2024/12/31'), false);
    });

    test('어제 종료된 축제는 ended', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 2));
      final date = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      expect(isFestivalEnded(date), true);
    });

    test('오늘 종료 예정인 축제는 아직 ended 아님', () {
      final today = DateTime.now();
      final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(isFestivalEnded(date), false);
    });

    test('미래 날짜이면 false', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final date = '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
      expect(isFestivalEnded(date), false);
    });

    test('과거 날짜이면 true', () {
      expect(isFestivalEnded('2020-01-01'), true);
    });
  });

  group('festivalDDaysUntil', () {
    test('isEnded=true이면 null 반환', () {
      expect(festivalDDaysUntil(startDate: '2099-12-31', isEnded: true), null);
    });

    test('startDate 빈 문자열이면 null 반환', () {
      expect(festivalDDaysUntil(startDate: '', isEnded: false), null);
    });

    test('잘못된 날짜 형식이면 null 반환', () {
      expect(festivalDDaysUntil(startDate: 'invalid', isEnded: false), null);
    });

    test('오늘 시작이면 0 반환', () {
      final today = DateTime.now();
      final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(festivalDDaysUntil(startDate: date, isEnded: false), 0);
    });

    test('내일 시작이면 1 반환', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      expect(festivalDDaysUntil(startDate: date, isEnded: false), 1);
    });

    test('7일 후 시작이면 7 반환', () {
      final future = DateTime.now().add(const Duration(days: 7));
      final date = '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
      expect(festivalDDaysUntil(startDate: date, isEnded: false), 7);
    });

    test('이미 시작한 경우 음수 반환', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      final date = '${past.year}-${past.month.toString().padLeft(2, '0')}-${past.day.toString().padLeft(2, '0')}';
      expect(festivalDDaysUntil(startDate: date, isEnded: false), -3);
    });
  });
}
