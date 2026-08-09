import 'package:feple/common/data/preference/prefs.dart';

/// 최근 검색어 목록 영속성 — AppPreferences(SharedPreferences 래퍼) 기반.
/// add/remove/clear가 겹쳐 호출되면 서로 stale한 스냅샷을 기준으로 저장해
/// 앞선 변경이 유실될 수 있으므로 내부 큐로 순차 실행되도록 체이닝.
///
/// 이 클래스는 목록을 내부 상태로 들고 있지 않고(단일 소스는 항상 호출자의
/// 상태) 매 호출마다 [current]를 받아 큐에 반영한 뒤 최신 목록을 반환한다 —
/// 큐 완료 시점의 최신 목록을 호출자가 알아야 UI를 갱신할 수 있기 때문에
/// mutate 후 값을 반환하는 것이 의도된 설계다.
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
