import 'package:feple/common/data/preference/prefs.dart';

/// 최근 검색어 목록 영속성 — AppPreferences(SharedPreferences 래퍼) 기반.
/// add/remove/clear가 겹쳐 호출되면 서로 stale한 스냅샷을 기준으로 저장해
/// 앞선 변경이 유실될 수 있으므로 내부 큐로 순차 실행되도록 체이닝.
class RecentSearchStore {
  static const _maxRecent = 10;

  Future<void> _queue = Future.value();

  List<String> load() => Prefs.recentSearches.get();

  Future<List<String>> add(List<String> current, String keyword) {
    if (keyword.trim().isEmpty) return Future.value(current);
    return _enqueue(current, (list) {
      list.remove(keyword);
      list.insert(0, keyword);
      if (list.length > _maxRecent) list.removeLast();
    });
  }

  Future<List<String>> remove(List<String> current, String keyword) {
    return _enqueue(current, (list) => list.remove(keyword));
  }

  Future<List<String>> clear() {
    return _enqueue([], (list) {});
  }

  Future<List<String>> _enqueue(List<String> current, void Function(List<String>) mutate) {
    final list = List<String>.from(current);
    mutate(list);
    final completer = _queue.then((_) => Prefs.recentSearches.set(list));
    _queue = completer;
    return completer.then((_) => list);
  }
}
