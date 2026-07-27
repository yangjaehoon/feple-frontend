import 'package:feple/model/my_timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/my_timetable_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

MyTimetableEntry _entry({
  String id = '1',
  String stageName = '메인',
  String label = '아티스트',
}) {
  return MyTimetableEntry(
    id: id,
    stageName: stageName,
    label: label,
    startTime: '18:00',
    endTime: '19:00',
    colorValue: 0xFFFF0000,
  );
}

void main() {
  group('MyTimetableStore.load', () {
    test('저장된 값이 없으면 빈 맵을 반환한다', () async {
      SharedPreferences.setMockInitialValues({});
      final store = MyTimetableStore(1);

      final result = await store.load();

      expect(result, isEmpty);
    });

    test('손상된 JSON이면 빈 맵을 반환한다', () async {
      SharedPreferences.setMockInitialValues({
        'user_timetable_entries_1': '{invalid json',
      });
      final store = MyTimetableStore(1);

      final result = await store.load();

      expect(result, isEmpty);
    });
  });

  group('MyTimetableStore.save/load 왕복', () {
    test('저장한 항목을 그대로 불러온다', () async {
      SharedPreferences.setMockInitialValues({});
      final store = MyTimetableStore(1);
      final entries = {
        '2026-08-01': [_entry(id: 'a', label: '아티스트A')],
        '2026-08-02': [_entry(id: 'b', label: '아티스트B'), _entry(id: 'c', label: '아티스트C')],
      };

      await store.save(entries);
      final loaded = await store.load();

      expect(loaded.keys, containsAll(['2026-08-01', '2026-08-02']));
      expect(loaded['2026-08-01']!.single.label, '아티스트A');
      expect(loaded['2026-08-02']!.map((e) => e.label), ['아티스트B', '아티스트C']);
    });

    test('festivalId가 다르면 서로 데이터를 공유하지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final store1 = MyTimetableStore(1);
      final store2 = MyTimetableStore(2);

      await store1.save({
        '2026-08-01': [_entry(label: '페스티벌1 일정')],
      });

      final store2Result = await store2.load();

      expect(store2Result, isEmpty);
    });
  });
}
