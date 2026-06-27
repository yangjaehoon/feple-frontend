import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/service/notification_service.dart';
import 'package:flutter/foundation.dart';

enum NotifFilter { all, cert, comment, festival }

class NotificationNotifier extends SafeChangeNotifier {
  final _service = sl<NotificationService>();

  List<NotificationModel> _items = [];
  bool isLoading = true;
  bool hasError = false;
  bool isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  NotifFilter filter = NotifFilter.all;

  DateTime? _loadedAt;
  static const _staleAfter = Duration(minutes: 3);
  bool get _isStale =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > _staleAfter;

  List<NotificationModel> get items => List.unmodifiable(_items);
  bool get hasUnread => _items.any((n) => !n.read);

  List<NotificationModel> get filtered {
    if (filter == NotifFilter.all) return _items;
    return _items.where((n) {
      final t = n.type;
      if (t == null) return false;
      return switch (filter) {
        NotifFilter.cert     => t.isCertType,
        NotifFilter.comment  => t.isCommentType,
        NotifFilter.festival => t.isFestivalFilterType,
        NotifFilter.all      => true,
      };
    }).toList();
  }

  Future<void> load() async {
    isLoading = true;
    hasError = false;
    _page = 0;
    _hasMore = true;
    _items = [];
    safeNotify();
    try {
      final result = await _service.fetchPage(0);
      _items = result.items;
      _hasMore = result.hasMore;
      _page = 1;
      _loadedAt = DateTime.now();
    } catch (_) {
      hasError = true;
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  /// [force] true면 항상 재요청. false면 stale 기준 이내 데이터가 있으면 skip.
  Future<void> refresh({bool force = false}) async {
    if (!force && _items.isNotEmpty && !_isStale) return;
    final result = await _service.fetchPage(0);
    _items = result.items;
    _hasMore = result.hasMore;
    _page = 1;
    hasError = false;
    _loadedAt = DateTime.now();
    safeNotify();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !_hasMore || isLoading) return;
    isLoadingMore = true;
    safeNotify();
    try {
      final result = await _service.fetchPage(_page);
      _items = [..._items, ...result.items];
      _hasMore = result.hasMore;
      _page++;
    } catch (_) {
      // 추가 로드 실패는 무시 — 다음 스크롤 시 재시도
    } finally {
      isLoadingMore = false;
      safeNotify();
    }
  }

  void setFilter(NotifFilter f) {
    if (filter == f) return;
    filter = f;
    safeNotify();
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
    }
  }

  Future<void> markAllRead() async {
    if (_items.every((n) => n.read)) return;
    _items = _items.map((n) => n.read ? n : n.copyWithRead()).toList();
    safeNotify();
    try {
      await _service.markAllRead();
    } catch (e) {
      debugPrint('[Notification] markAllRead error: $e');
    }
  }

  Future<void> dismiss(NotificationModel item) async {
    final index = _items.indexWhere((n) => n.id == item.id);
    if (index < 0) return;
    _items.removeAt(index);
    safeNotify();
    // adminBroadcast는 개별 read API 대상이 아님 — 로컬에서만 제거
    if (item.type == NotificationType.adminBroadcast) return;
    try {
      await _service.markRead(item.id);
    } catch (e) {
      debugPrint('[Notification] markRead 실패: $e');
    }
  }

  // 실행취소 지원 분리 메서드 — UI에서 직접 사용
  void removeLocally(NotificationModel item) {
    _items.removeWhere((n) => n.id == item.id);
    safeNotify();
  }

  void undoDismiss(NotificationModel item) {
    if (_items.any((n) => n.id == item.id)) return;
    _items.insert(0, item);
    safeNotify();
  }

  Future<void> confirmDismiss(NotificationModel item) async {
    if (item.type == NotificationType.adminBroadcast) return;
    try {
      await _service.markRead(item.id);
    } catch (e) {
      debugPrint('[Notification] markRead 실패: $e');
    }
  }
}
