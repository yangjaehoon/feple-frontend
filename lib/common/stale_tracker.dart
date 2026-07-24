/// 데이터가 마지막으로 로드된 시점을 추적해 일정 시간이 지나면 stale로 판단.
class StaleTracker {
  final Duration staleAfter;
  DateTime? _loadedAt;

  StaleTracker(this.staleAfter);

  bool get isStale =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > staleAfter;

  void markLoaded() => _loadedAt = DateTime.now();
}
