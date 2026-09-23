import 'package:dio/dio.dart' show CancelToken;
import 'package:feple/common/common.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/forced_refresh.dart';
import 'package:feple/common/util/request_scope.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:flutter/material.dart';

/// 상태 필터가 있는 "내 활동" 목록 화면(인증 내역, 신청곡 내역 등)에서 반복되던
/// load/refresh/필터 상태 관리와 로딩·에러·빈 상태 분기를 공통화. 화면별 State가
/// fetchItems()/statusOf()만 구현하면 되고, 스켈레톤·빈 상태·아이템 렌더링은
/// 화면마다 그대로 담당한다.
mixin FilteredStatusListState<T, S, W extends StatefulWidget> on State<W> {
  Future<List<T>> fetchItems();
  S? statusOf(T item);

  List<T> items = [];
  bool isLoadingItems = true;
  bool hasLoadError = false;
  Object? loadError;
  S? filter; // null = 전체

  final CancelToken _cancelToken = CancelToken();

  List<T> get filteredItems =>
      filter == null ? items : items.where((i) => statusOf(i) == filter).toList();

  @override
  void dispose() {
    if (!_cancelToken.isCancelled) _cancelToken.cancel('widget disposed');
    super.dispose();
  }

  Future<void> loadItems() async {
    setState(() {
      isLoadingItems = true;
      hasLoadError = false;
    });
    try {
      final list = await withCancelScope(_cancelToken, fetchItems);
      if (mounted) {
        setState(() {
          items = list;
          isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingItems = false;
          hasLoadError = true;
          loadError = e;
        });
      }
    }
  }

  /// 당겨서 새로고침 + 로딩/에러/빈 상태 분기를 공통 처리하고, 실제 목록은
  /// [listBuilder]에 필터링된 아이템을 넘겨 화면이 그리게 한다.
  /// 에러·빈 상태는 RefreshIndicator가 감지하도록 스크롤 가능하게 감싼다.
  Widget buildFilteredBody({
    required AbstractThemeColors colors,
    required Widget skeleton,
    required Widget emptyState,
    required Widget Function(List<T> items) listBuilder,
  }) {
    final displayed = filteredItems;
    return RefreshIndicator(
      onRefresh: () => withForcedRefresh(refreshItems),
      color: colors.activate,
      child: isLoadingItems
          ? skeleton
          : hasLoadError
              ? RefreshableCenter(
                  child: ErrorState.network(loadError!, onRetry: loadItems),
                )
              : displayed.isEmpty
                  ? RefreshableCenter(child: emptyState)
                  : listBuilder(displayed),
    );
  }

  // RefreshIndicator용 — 기존 목록 유지, 스켈레톤 전환 없음. 실패해도 목록은
  // 유지하되(크래시 방지), 실패 사실은 알려야 한다
  Future<void> refreshItems() async {
    try {
      final list = await withCancelScope(_cancelToken, fetchItems);
      if (mounted) {
        setState(() {
          items = list;
          hasLoadError = false;
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackbar(fetchFailureText(e));
    }
  }
}
