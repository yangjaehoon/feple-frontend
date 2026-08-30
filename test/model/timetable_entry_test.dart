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

    test('startHour — 첫 아티스트 공연 시각 기준 (12시 이전)', () {
      final result = computeTimetableRange(
        [_entry(startTime: '08:30', endTime: '10:00')],
        '2025-08-01',
      );

      expect(result.startHour, 8);
    });

    test('startHour — 첫 아티스트 공연 시각 기준 (12시 이후여도 그 시각부터)', () {
      final result = computeTimetableRange(
        [
          _entry(id: 1, startTime: '16:00', endTime: '17:00'),
          _entry(id: 2, startTime: '14:00', endTime: '15:00'),
        ],
        '2025-08-01',
      );

      expect(result.startHour, 14);
    });

    test('startHour — 운영 항목(📢)은 기준에서 제외', () {
      final result = computeTimetableRange(
        [
          _entry(
              id: 1,
              stageName: TimetableEntry.opsStageName,
              startTime: '10:00',
              endTime: '10:30'),
          _entry(id: 2, startTime: '16:00', endTime: '17:00'),
        ],
        '2025-08-01',
      );

      expect(result.startHour, 16);
    });

    test('startHour — 아티스트 공연 없이 운영 항목만 있으면 첫 운영 항목 시각 기준', () {
      final result = computeTimetableRange(
        [
          _entry(
              id: 1,
              stageName: TimetableEntry.opsStageName,
              startTime: '13:00',
              endTime: '13:30'),
          _entry(
              id: 2,
              stageName: TimetableEntry.opsStageName,
              startTime: '10:00',
              endTime: '10:30'),
        ],
        '2025-08-01',
      );

      expect(result.startHour, 10);
    });

    test('startHour — 심야(0~5시) 아티스트 항목은 자정 넘김으로 보고 제외', () {
      final result = computeTimetableRange(
        [
          _entry(id: 1, startTime: '00:30', endTime: '01:30'),
          _entry(id: 2, startTime: '18:00', endTime: '19:00'),
          _entry(id: 3, startTime: '20:00', endTime: '21:00'),
        ],
        '2025-08-01',
      );

      expect(result.startHour, 18);
    });

    test('startHour — 모든 항목이 심야면 그 최솟값을 사용', () {
      final result = computeTimetableRange(
        [
          _entry(id: 1, startTime: '03:00', endTime: '04:00'),
          _entry(id: 2, startTime: '02:00', endTime: '03:00'),
        ],
        '2025-08-01',
      );

      expect(result.startHour, 2);
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

    test('endHour — 자정을 넘기는 공연은 그리드가 다음날 시각까지 확장된다', () {
      // 23:30 시작, 00:30(다음날) 종료 — endTime을 그대로 파싱하면 endHour가
      // 1로 잡혀 카드가 그리드 하단에서 잘리므로, durationMinutes 기반으로
      // 24시를 넘는 종료 시각(24.5h → ceil 25)까지 그리드를 확장해야 한다.
      final result = computeTimetableRange(
        [_entry(startTime: '23:30', endTime: '00:30')],
        '2025-08-01',
      );

      expect(result.endHour, 25);
    });

    test('endHour — 심야에 시작하는 항목도 다음날 시각으로 환산해 확장', () {
      // startHour는 저녁(18)부터. 01:00~02:30 세트는 25:00~26:30으로 환산돼
      // endHour가 27까지 확장돼야 카드가 안 잘린다.
      final result = computeTimetableRange(
        [
          _entry(id: 1, startTime: '18:00', endTime: '19:00'),
          _entry(id: 2, startTime: '01:00', endTime: '02:30'),
        ],
        '2025-08-01',
      );

      expect(result.startHour, 18);
      expect(result.endHour, 27);
    });
  });

  group('hourInFestivalDay', () {
    test('startHour가 낮/저녁이면 심야(0~5시)는 +24, 6시 이상은 그대로', () {
      expect(hourInFestivalDay(0, 18), 24);
      expect(hourInFestivalDay(5, 18), 29);
      expect(hourInFestivalDay(6, 18), 6);
      expect(hourInFestivalDay(23, 18), 23);
    });

    test('startHour 자체가 심야면(밤샘 페스티벌) 롤오버하지 않는다', () {
      expect(hourInFestivalDay(3, 2), 3);
      expect(hourInFestivalDay(1, 1), 1);
    });
  });

  group('timetableMinutesToY', () {
    test('일반 항목은 startHour 기준 오프셋', () {
      expect(timetableMinutesToY('14:30', 12, 1.0), (14 - 12) * 60 + 30);
    });

    test('심야 항목은 다음날로 밀려 그리드 하단에 위치', () {
      // 01:00 → 25:00, startHour 18 → (25-18)*60 = 420
      expect(timetableMinutesToY('01:00', 18, 1.0), 420);
    });

    test('startHour보다 이른 낮 항목(게이트 오픈 등)은 상단(0)에 고정', () {
      // 10:00, startHour 18 → 음수이므로 0으로 클램프
      expect(timetableMinutesToY('10:00', 18, 2.0), 0);
    });
  });
}
