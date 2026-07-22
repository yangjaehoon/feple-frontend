import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/stale_tracker.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/service/notification_feedable.dart';
import 'package:flutter/foundation.dart';

export 'package:feple/service/notification_feedable.dart' show NotificationFilter;

class NotificationNotifier extends SafeChangeNotifier {
  final _service = sl<NotificationFeedable>();

  List<NotificationModel> _items = [];
  bool isLoading = true;
  bool hasError = false;
  bool isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  NotificationFilter filter = NotificationFilter.all;

  // 원위치 복원용: id → 제거 전 인덱스
  final Map<int, int> _savedPositions = {};

  // 전체 삭제 실행취소용: 삭제 직전 전체 목록 스냅샷
  List<NotificationModel>? _savedAllItems;

  final _staleness = StaleTracker(const Duration(minutes: 3));

  List<NotificationModel> get items => List.unmodifiable(_items);
  bool get hasUnread => _items.any((n) => !n.read);

  Future<void> load() async {
    isLoading = true;
    hasError = false;
    _page = 0;
    _hasMore = true;
    _items = [];
    _savedPositions.clear();
    safeNotify();
    try {
      final result = await _service.fetchPage(0, filter: filter);
      _items = result.items;
      _hasMore = result.hasMore;
      _page = 1;
      _staleness.markLoaded();
    } catch (_) {
      hasError = true;
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (!force && _items.isNotEmpty && !_staleness.isStale) return;
    final result = await _service.fetchPage(0, filter: filter);
    _items = result.items;
    _hasMore = result.hasMore;
    _page = 1;
    hasError = false;
    _staleness.markLoaded();
    safeNotify();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !_hasMore || isLoading) return;
    isLoadingMore = true;
    safeNotify();
    try {
      final result = await _service.fetchPage(_page, filter: filter);
      _items = [..._items, ...result.items];
      _hasMore = result.hasMore;
      _page++;
    } catch (e) {
      // 추가 로드 실패는 무시 — 다음 스크롤 시 재시도
      debugPrint('notification loadMore error: $e');
    } finally {
      isLoadingMore = false;
      safeNotify();
    }
  }

  void setFilter(NotificationFilter filter) {
    if (this.filter == filter) return;
    this.filter = filter;
    load();
  }

  Future<void> markRead(NotificationModel item) async {
    final index = _items.indexWhere((n) => n.id == item.id);
    if (index < 0 || item.read) return;
    _items[index] = item.copyWithRead();
    safeNotify();
    try {
      await _service.markRead(item.id);
    } catch (e) {
      debugPrint('markRead error: $e');
      final rollbackIndex = _items.indexWhere((n) => n.id == item.id);
      if (rollbackIndex >= 0) {
        _items[rollbackIndex] = item;
        safeNotify();
      }
    }
  }

  Future<void> markAllRead() async {
    if (_items.every((n) => n.read)) return;
    final original = List<NotificationModel>.from(_items);
    _items = _items.map((n) => n.read ? n : n.copyWithRead()).toList();
    safeNotify();
    try {
      await _service.markAllRead();
    } catch (e) {
      debugPrint('[Notification] markAllRead error: $e');
      _items = original;
      safeNotify();
    }
  }

  // 실행취소 지원: 로컬에서 제거하고 원래 인덱스 저장
  void removeLocally(NotificationModel item) {
    final index = _items.indexWhere((n) => n.id == item.id);
    if (index < 0) return;
    _savedPositions[item.id] = index;
    _items.removeAt(index);
    safeNotify();
  }

  void undoDismiss(NotificationModel item) {
    if (_items.any((n) => n.id == item.id)) return;
    final savedIndex = _savedPositions.remove(item.id);
    final insertAt = (savedIndex != null && savedIndex <= _items.length)
        ? savedIndex
        : 0;
    _items.insert(insertAt, item);
    safeNotify();
  }

  Future<void> confirmDismiss(NotificationModel item) async {
    _savedPositions.remove(item.id);
    try {
      await _service.delete(item.id);
    } catch (e) {
      debugPrint('[Notification] delete 실패: $e');
    }
  }

  // 실행취소 지원: 개별 삭제(removeLocally/undoDismiss/confirmDismiss)와
  // 동일하게 로컬에서 먼저 비우고, 실행취소 스낵바가 끝난 뒤에만 서버에서
  // 실제 삭제를 확정한다 — 전체 삭제는 개별 삭제보다 되돌릴 수 없는 피해가
  // 크므로 같은 안전장치를 반드시 제공해야 함
  void removeAllLocally() {
    _savedAllItems = List<NotificationModel>.from(_items);
    _items = [];
    _savedPositions.clear();
    safeNotify();
  }

  void undoDeleteAll() {
    final saved = _savedAllItems;
    if (saved == null) return;
    _items = saved;
    _savedAllItems = null;
    safeNotify();
  }

  Future<void> confirmDeleteAll() async {
    _savedAllItems = null;
    try {
      await _service.deleteAll();
    } catch (e) {
      debugPrint('[Notification] deleteAll 실패: $e');
    }
  }
}
