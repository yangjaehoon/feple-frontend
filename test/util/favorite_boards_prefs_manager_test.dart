import 'package:feple/screen/main/tab/home/favorite_boards_prefs_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FavoriteBoardsPrefsManager manager;

  setUp(() {
    manager = FavoriteBoardsPrefsManager(1);
  });

  group('load', () {
    test('저장된 값이 없으면 전체 목록을 그대로 반환한다', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await manager.load(['a', 'b', 'c']);

      expect(result, ['a', 'b', 'c']);
    });

    test('선택 목록이 저장되어 있으면 그 순서를 따른다', () async {
      SharedPreferences.setMockInitialValues({
        'fav_boards_1': ['c', 'a'],
      });

      final result = await manager.load(['a', 'b', 'c']);

      expect(result, ['c', 'a']);
    });

    test('저장된 선택 목록에 더는 존재하지 않는 게시판은 제외한다', () async {
      SharedPreferences.setMockInitialValues({
        'fav_boards_1': ['removed', 'a'],
      });

      final result = await manager.load(['a', 'b']);

      expect(result, ['a']);
    });

    test('알려진 목록 이후 새로 추가된 게시판은 자동으로 뒤에 붙는다', () async {
      SharedPreferences.setMockInitialValues({
        'fav_boards_1': ['a'],
        'fav_boards_known_1': ['a', 'b'],
      });

      final result = await manager.load(['a', 'b', 'new']);

      expect(result, ['a', 'new']);
    });

    test('선택 목록은 없지만 순서만 저장되어 있으면 순서를 따른다', () async {
      SharedPreferences.setMockInitialValues({
        'fav_boards_order_1': ['b', 'a'],
      });

      final result = await manager.load(['a', 'b']);

      expect(result, ['b', 'a']);
    });
  });

  group('save', () {
    test('전체를 선택한 상태로 저장하면 선택 목록 키는 제거된다', () async {
      SharedPreferences.setMockInitialValues({
        'fav_boards_1': ['a'],
      });

      await manager.save(['a', 'b'], ['a', 'b']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('fav_boards_1'), isNull);
      expect(prefs.getStringList('fav_boards_order_1'), ['a', 'b']);
      expect(prefs.getStringList('fav_boards_known_1'), ['a', 'b']);
    });

    test('일부만 선택한 상태로 저장하면 선택 목록이 함께 저장된다', () async {
      SharedPreferences.setMockInitialValues({});

      await manager.save(['a'], ['a', 'b']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('fav_boards_1'), ['a']);
      expect(prefs.getStringList('fav_boards_known_1'), ['a', 'b']);
    });
  });
}
