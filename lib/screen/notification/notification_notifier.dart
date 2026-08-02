import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/stale_tracker.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/service/notification_feedable.dart';
import 'package:flutter/foundation.dart';

export 'package:feple/service/notification_feedable.dart'
    show NotificationFilter;

class NotificationNotifier extends SafeChangeNotifier {
  final _service = sl<NotificationFeedable>();

  List<NotificationModel> _items = [];
  bool isLoading = true;
  bool hasError = false;
  Object? error;
  bool isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  NotificationFilter filter = NotificationFilter.all;

  // 원위치 복원용: id → 제거 전 인덱스
  final Map<int, int> _savedPositions = {};

  // 전체 삭제 실행취소용: 삭제 직전 전체 목록 스냅샷
  List<NotificationModel>? _savedAllItems;

  // confirmDismiss/confirmDeleteAll의 서버 삭제가 실패했을 때 설정 — UI가
  // snackbar로 표시 후 clearDeleteError() 호출 (일회성)
  String? _deleteError;
  String? get deleteError => _deleteError;
  void clearDeleteError() => _deleteError = null;

  final _staleness = StaleTracker(const Duration(minutes: 3));

  // 화면 재진입 시 새 Notifier 인스턴스가 만들어지므로, 서버 삭제가 아직
  // 확정되지 않은(실행취소 대기 중인) 항목은 인스턴스가 아닌 클래스 레벨로
  // 추적해야 재조회 목록에서도 계속 숨길 수 있다.
  static final Set<int> _pendingDeleteIds = {};

  @visibleForTesting
  static void resetPendingDeletesForTest() => _pendingDeleteIds.clear();

  List<NotificationModel> get items => List.unmodifiable(_items);
  bool get hasUnread => _items.any((n) => !n.read);

  // AppBar의 "모두 읽음" 아이콘·필터 칩 선택 상태는 리스트 전체와 무관하게
  // 독립적으로 구독되도록 ValueNotifier로 분리 — ValueNotifier는 실제 값이
  // 바뀔 때만 notify하므로, 알림 하나를 읽음 처리해도(다른 안 읽은 알림이
  // 남아있는 한 hasUnread는 안 바뀜) AppBar·필터 칩까지 매번 리빌드되지 않음.
  final hasUnreadNotifier = ValueNotifier<bool>(false);
  final filterNotifier = ValueNotifier<NotificationFilter>(NotificationFilter.all);

  @override
  void dispose() {
    hasUnreadNotifier.dispose();
    filterNotifier.dispose();
    super.dispose();
  }

  void _notify() {
    // isDisposed 체크: 위젯이 이미 dispose된 뒤 markRead 등의 async 콜백이
    // 늦게 완료되면 hasUnreadNotifier/filterNotifier(일반 ValueNotifier,
    // safeNotify 아님)에 값을 대입하다 "used after being disposed" 예외가 날 수 있음
    if (!isDisposed) {
      hasUnreadNotifier.value = hasUnread;
      filterNotifier.value = filter;
    }
    safeNotify();
  }

  Future<void> load() async {
    isLoading = true;
    hasError = false;
    _page = 0;
    _hasMore = true;
    _items = [];
    _savedPositions.clear();
    _notify();
    try {
      final result = await _service.fetchPage(0, filter: filter);
      _items = _excludePendingDeletes(result.items);
      _hasMore = result.hasMore;
      _page = 1;
      _staleness.markLoaded();
    } catch (e) {
      hasError = true;
      error = e;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (!force && _items.isNotEmpty && !_staleness.isStale) return;
    final result = await _service.fetchPage(0, filter: filter);
    _items = _excludePendingDeletes(result.items);
    _hasMore = result.hasMore;
    _page = 1;
    hasError = false;
    _staleness.markLoaded();
    _notify();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !_hasMore || isLoading) return;
    isLoadingMore = true;
    _notify();
    try {
      final result = await _service.fetchPage(_page, filter: filter);
      _items = [..._items, ..._excludePendingDeletes(result.items)];
      _hasMore = result.hasMore;
      _page++;
    } catch (e) {
      // 추가 로드 실패는 무시 — 다음 스크롤 시 재시도
      debugPrint('notification loadMore error: $e');
    } finally {
      isLoadingMore = false;
      _notify();
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
    _notify();
    try {
      await _service.markRead(item.id);
    } catch (e) {
      debugPrint('markRead error: $e');
      final rollbackIndex = _items.indexWhere((n) => n.id == item.id);
      if (rollbackIndex >= 0) {
        _items[rollbackIndex] = item;
        _notify();
      }
    }
  }

  Future<void> markAllRead() async {
    if (_items.every((n) => n.read)) return;
    final original = List<NotificationModel>.from(_items);
    _items = _items.map((n) => n.read ? n : n.copyWithRead()).toList();
    _notify();
    try {
      await _service.markAllRead();
    } catch (e) {
      debugPrint('[Notification] markAllRead error: $e');
      _items = original;
      _notify();
    }
  }

  List<NotificationModel> _excludePendingDeletes(List<NotificationModel> items) {
    if (_pendingDeleteIds.isEmpty) return items;
    return items.where((n) => !_pendingDeleteIds.contains(n.id)).toList();
  }

  // 실행취소 지원: 로컬에서 제거하고 원래 인덱스 저장
  void removeLocally(NotificationModel item) {
    final index = _items.indexWhere((n) => n.id == item.id);
    if (index < 0) return;
    _savedPositions[item.id] = index;
    _pendingDeleteIds.add(item.id);
    _items.removeAt(index);
    _notify();
  }

  void undoDismiss(NotificationModel item) {
    if (_items.any((n) => n.id == item.id)) return;
    _pendingDeleteIds.remove(item.id);
    final savedIndex = _savedPositions.remove(item.id);
    final insertAt = (savedIndex != null && savedIndex <= _items.length)
        ? savedIndex
        : 0;
    _items.insert(insertAt, item);
    _notify();
  }

  Future<void> confirmDismiss(NotificationModel item) async {
    final savedIndex = _savedPositions.remove(item.id);
    try {
      await _service.delete(item.id);
    } catch (e) {
      debugPrint('[Notification] delete 실패: $e');
      // 서버 삭제가 실패했는데 로컬에서만 지워진 채로 두면, pendingDeleteIds가
      // finally에서 정리되므로 다음 재조회 때 서버에 남아있던 항목이 예고 없이
      // 다시 나타난다 — 실패 시 즉시 화면에 복원하고 사용자에게 알린다
      if (!_items.any((n) => n.id == item.id)) {
        final insertAt = (savedIndex != null && savedIndex <= _items.length) ? savedIndex : 0;
        _items.insert(insertAt, item);
      }
      _deleteError = 'delete_failed'.tr();
    } finally {
      _pendingDeleteIds.remove(item.id);
      _notify();
    }
  }

  // 실행취소 지원: 개별 삭제(removeLocally/undoDismiss/confirmDismiss)와
  // 동일하게 로컬에서 먼저 비우고, 실행취소 스낵바가 끝난 뒤에만 서버에서
  // 실제 삭제를 확정한다 — 전체 삭제는 개별 삭제보다 되돌릴 수 없는 피해가
  // 크므로 같은 안전장치를 반드시 제공해야 함
  void removeAllLocally() {
    _savedAllItems = List<NotificationModel>.from(_items);
    _pendingDeleteIds.addAll(_savedAllItems!.map((n) => n.id));
    _items = [];
    _savedPositions.clear();
    _notify();
  }

  void undoDeleteAll() {
    final saved = _savedAllItems;
    if (saved == null) return;
    _pendingDeleteIds.removeAll(saved.map((n) => n.id));
    _items = saved;
    _savedAllItems = null;
    _notify();
  }

  Future<void> confirmDeleteAll() async {
    final saved = _savedAllItems;
    _savedAllItems = null;
    try {
      await _service.deleteAll();
    } catch (e) {
      debugPrint('[Notification] deleteAll 실패: $e');
      // 전체 삭제가 서버에서 실패했는데 로컬은 이미 비어있는 채로 두면, 다음
      // 재조회 때 서버에 남아있던 항목들이 예고 없이 다시 나타난다 — 실패 시
      // 즉시 화면에 복원하고 사용자에게 알린다
      if (saved != null) _items = saved;
      _deleteError = 'delete_failed'.tr();
    } finally {
      if (saved != null) _pendingDeleteIds.removeAll(saved.map((n) => n.id));
      _notify();
    }
  }
}
