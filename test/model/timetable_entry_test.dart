import 'package:feple/model/timetable_entry.dart';
import 'package:flutter_test/flutter_test.dart';

TimetableEntry _entry({
  int id = 1,
  String stageName = 'Main',
  int stageOrder = 1,
  String artistName = 'Artist',
  String festivalDate = '2025-08-01',
  String startTime = '15:00',
  String endTime = '16:00',
}) =>
    TimetableEntry(
      id: id,
      stageName: stageName,
      stageOrder: stageOrder,
      artistName: artistName,
      festivalDate: festivalDate,
      startTime: startTime,
      endTime: endTime,
    );

void main() {
  group('TimetableEntry.fromJson', () {
    test('정상 필드 파싱 및 _toHHmm 변환', () {
      final json = {
        'id': 1,
        'stageName': 'Main Stage',
        'stageOrder': 2,
        'artistName': '아티스트',
        'festivalDate': '2025-08-01',
        'startTime': '15:30:00',
        'endTime': '17:00:00',
      };

      final entry = TimetableEntry.fromJson(json);

      expect(entry.id, 1);
      expect(entry.stageName, 'Main Stage');
      expect(entry.stageOrder, 2);
      expect(entry.startTime, '15:30');
      expect(entry.endTime, '17:00');
    });

    test('null 필드 기본값 적용', () {
      final json = {
        'id': null,
        'stageName': null,
        'stageOrder': null,
        'artistName': null,
        'festivalDate': null,
        'startTime': null,
        'endTime': null,
      };

      final entry = TimetableEntry.fromJson(json);

      expect(entry.id, 0);
      expect(entry.stageName, '');
      expect(entry.stageOrder, 999);
      expect(entry.artistName, '');
      expect(entry.startTime, '');
      expect(entry.endTime, '');
    });

    test('startTime 5자 미만이면 그대로 반환', () {
      final entry = TimetableEntry.fromJson({
        'id': 1,
        'stageName': 'S',
        'stageOrder': 1,
        'artistName': 'A',
        'festivalDate': '2025-08-01',
        'startTime': '9:30',
        'endTime': '10:00',
      });

      expect(entry.startTime, '9:30');
    });
  });

  group('TimetableEntry.durationMinutes', () {
    test('90분 공연', () {
      expect(_entry(startTime: '09:00', endTime: '10:30').durationMinutes, 90);
    });

    test('시작·종료 같으면 0분', () {
      expect(_entry(startTime: '09:00', endTime: '09:00').durationMinutes, 0);
    });

    test('자정을 넘기는 공연은 다음날로 간주해 계산', () {
      expect(_entry(startTime: '23:30', endTime: '00:30').durationMinutes, 60);
    });

    test('잘못된 시간 포맷이면 0 반환', () {
      expect(_entry(startTime: 'invalid', endTime: 'bad').durationMinutes, 0);
    });
  });

  group('TimetableEntry.timeRange', () {
    test('startTime – endTime 포맷 반환', () {
      expect(
        _entry(startTime: '15:00', endTime: '16:30').timeRange,
        '15:00 – 16:30',
      );
    });
  });

  group('computeTimetableRange', () {
    test('date null이면 빈 결과·startHour=12·endHour=13', () {
      final result = computeTimetableRange([_entry()], null);

      expect(result.filtered, isEmpty);
      expect(result.stages, isEmpty);
      expect(result.startHour, 12);
      expect(result.endHour, 13);
    });

    test('날짜 필터 — 해당 날짜 항목만 포함', () {
      final entries = [
        _entry(id: 1, festivalDate: '2025-08-01'),
        _entry(id: 2, festivalDate: '2025-08-02'),
      ];

      final result = computeTimetableRange(entries, '2025-08-01');

      expect(result.filtered.length, 1);
      expect(result.filtered.first.id, 1);
    });

    test('해당 날짜 항목 없으면 빈 결과·기본값 유지', () {
      final result =
          computeTimetableRange([_entry(festivalDate: '2025-08-02')], '2025-08-01');

      expect(result.filtered, isEmpty);
      expect(result.startHour, 12);
      expect(result.endHour, 13);
    });

    test('스테이지 stageOrder 오름차순 정렬', () {
      final entries = [
        _entry(stageName: 'C', stageOrder: 3),
        _entry(stageName: 'A', stageOrder: 1),
        _entry(stageName: 'B', stageOrder: 2),
      ];

      final result = computeTimetableRange(entries, '2025-08-01');

      expect(result.stages, ['A', 'B', 'C']);
    });

    test('startHour — 기본값(12)보다 이른 항목 있으면 갱신', () {
      final result = computeTimetableRange(
        [_entry(startTime: '08:30', endTime: '10:00')],
        '2025-08-01',
      );

      expect(result.startHour, 8);
    });

    test('startHour — 모든 항목이 12시 이후이면 12 유지', () {
      final result = computeTimetableRange(
        [_entry(startTime: '14:00', endTime: '15:00')],
        '2025-08-01',
      );

      expect(result.startHour, 12);
    });

    test('endHour — 분=0이면 시 그대로', () {
      final result = computeTimetableRange(
        [_entry(startTime: '15:00', endTime: '17:00')],
        '2025-08-01',
      );

      expect(result.endHour, 17);
    });

    test('endHour — 분>0이면 시+1', () {
      final result = computeTimetableRange(
        [_entry(startTime: '15:00', endTime: '17:30')],
        '2025-08-01',
      );

      expect(result.endHour, 18);
    });

    test('endHour — 여러 항목 중 최댓값 선택', () {
      final entries = [
        _entry(id: 1, startTime: '14:00', endTime: '16:00'),
        _entry(id: 2, startTime: '15:00', endTime: '19:30'),
      ];

      final result = computeTimetableRange(entries, '2025-08-01');

      expect(result.endHour, 20);
    });
  });
}
