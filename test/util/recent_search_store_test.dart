import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/screen/main/tab/search/recent_search_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RecentSearchStore store;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() async {
    // AppPreferences._prefs는 static late 필드라 setUpAll에서 한 번만 초기화할 수
    // 있음 — 테스트 간 저장값이 새어나가지 않도록 매 테스트 전에 직접 비운다.
    await Prefs.recentSearches.set([]);
    store = RecentSearchStore();
  });

  group('add', () {
    test('새 검색어를 맨 앞에 추가한다', () async {
      final result = await store.add(['a', 'b'], 'c');

      expect(result, ['c', 'a', 'b']);
    });

    test('이미 있는 검색어면 맨 앞으로 옮긴다', () async {
      final result = await store.add(['a', 'b', 'c'], 'b');

      expect(result, ['b', 'a', 'c']);
    });

    test('빈 문자열은 추가하지 않는다', () async {
      final result = await store.add(['a'], '   ');

      expect(result, ['a']);
    });

    test('10개를 초과하면 가장 오래된 항목을 제거한다', () async {
      final current = List.generate(10, (i) => 'kw$i');

      final result = await store.add(current, 'new');

      expect(result.length, 10);
      expect(result.first, 'new');
      expect(result.contains('kw9'), isFalse);
    });
  });

  group('remove', () {
    test('지정한 검색어를 제거한다', () async {
      final result = await store.remove(['a', 'b', 'c'], 'b');

      expect(result, ['a', 'c']);
    });
  });

  group('clear', () {
    test('전체 목록을 비운다', () async {
      final result = await store.clear();

      expect(result, isEmpty);
    });
  });

  group('load', () {
    test('저장된 값이 없으면 빈 목록을 반환한다', () {
      expect(store.load(), isEmpty);
    });

    test('저장된 값을 그대로 불러온다', () async {
      await store.add([], '검색어');

      expect(store.load(), ['검색어']);
    });
  });
}
