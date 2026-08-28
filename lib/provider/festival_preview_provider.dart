import 'package:dio/dio.dart' show CancelToken;
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/stale_tracker.dart';
import 'package:feple/common/util/debouncer.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/request_scope.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

import '../model/festival_preview.dart';

class FestivalPreviewProvider extends SafeChangeNotifier {
  FestivalPreviewProvider(this._service) {
    refresh();
  }

  final FestivalService _service;

  final List<FestivalPreview> _items = [];
  List<FestivalPreview> _cachedItems = const [];
  // context.select 비교가 참조 동등성을 사용하므로, items 내용이 바뀔 때만 새 참조 생성
  List<FestivalPreview> get items => _cachedItems;

  // 불변 Set으로 유지 — 참조가 바뀔 때만 context.select가 재빌드하도록
  Set<String> _selectedGenres = const {};
  Set<String> _selectedRegions = const {};
  Set<String> _selectedAgeRestrictions = const {};
  Set<String> get selectedGenres => _selectedGenres;
  Set<String> get selectedRegions => _selectedRegions;
  Set<String> get selectedAgeRestrictions => _selectedAgeRestrictions;
  bool get hasActiveFilters =>
      _selectedGenres.isNotEmpty ||
      _selectedRegions.isNotEmpty ||
      _selectedAgeRestrictions.isNotEmpty;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  Object? _error;
  Object? get error => _error;
  // page 0 refresh 실패 + 기존 아이템 있을 때 설정 — UI가 snackbar로 표시 후 clearRefreshError() 호출
  String? _refreshError;
  String? get refreshError => _refreshError;

  void clearRefreshError() => _refreshError = null;
  int _page = 0;
  final int _size = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final _staleness = StaleTracker(const Duration(minutes: 5));

  // 연속 필터 변경 시 마지막 변경 후 debounceFilter(400ms) 뒤에만 API 호출
  final _filterDebounce = Debouncer(AppDimens.debounceFilter);

  // 필터 변경으로 무효화된 요청의 응답이 늦게 도착해 최신 결과를 덮어쓰지 않도록 가드.
  // (mock 기반 단위 테스트처럼 취소를 존중하지 않는 fetch 경로에서도 동작)
  int _generation = 0;
  // 현재 진행 중인 fetchNext의 세대. 이전 세대 요청이 아직 unwind 중이어도
  // 새 세대 요청이 곧바로 시작될 수 있게 한다 (예전엔 _isLoading을 강제 리셋했음).
  int? _activeFetchGeneration;

  // 필터 변경 시 진행 중이던 실제 네트워크 요청을 중단해 낭비를 없앤다.
  // (_generation은 결과를 "무시"만 할 뿐, 요청 자체는 계속 나가고 있었음)
  CancelToken _fetchToken = CancelToken();

  void _toggleInSet(
    Set<String> current,
    String value,
    void Function(Set<String>) assign,
  ) {
    final updated = current.contains(value)
        ? current.where((e) => e != value).toSet()
        : {...current, value};
    assign(Set.unmodifiable(updated));
    _scheduleFetch();
  }

  void toggleGenre(String genre) =>
      _toggleInSet(_selectedGenres, genre, (s) => _selectedGenres = s);
  void toggleRegion(String region) =>
      _toggleInSet(_selectedRegions, region, (s) => _selectedRegions = s);
  void toggleAgeRestriction(String ageRestriction) => _toggleInSet(
    _selectedAgeRestrictions,
    ageRestriction,
    (s) => _selectedAgeRestrictions = s,
  );

  void clearFilters() {
    _selectedGenres = const {};
    _selectedRegions = const {};
    _selectedAgeRestrictions = const {};
    _scheduleFetch();
  }

  void _scheduleFetch() {
    _filterDebounce.run(_clearAndFetch);
    safeNotify(); // 칩 상태 즉시 반영
  }

  // 필터 변경 확정 후: 즉시 목록 비우고 재요청
  void _clearAndFetch() {
    // 이전 세대(진행 중이던 요청)를 무효화 — 그 응답이 나중에 와도 결과를 반영하지 않고,
    // 실제 네트워크 요청도 CancelToken으로 중단한다. 새 fetchNext는 세대가 달라
    // 진입 가드를 통과하므로 busy 플래그를 건드릴 필요가 없다.
    _generation++;
    _fetchToken.cancel();
    _fetchToken = CancelToken();
    _items.clear();
    _cachedItems = const [];
    _page = 0;
    _hasMore = true;
    _error = null;
    safeNotify();
    fetchNext();
  }

  /// [force] true면 항상 재요청. false면 5분 이내 데이터가 있으면 skip.
  /// 당겨서 새로고침은 force: true, 화면 복귀 후 자동 호출은 force: false.
  Future<void> refresh({bool force = false}) async {
    if (!force && _items.isNotEmpty && !_staleness.isStale) return;
    _page = 0;
    _hasMore = true;
    _error = null;
    // 기존 items 유지 — fetchNext에서 page 0 성공 시 교체
    await fetchNext();
  }

  Future<void> fetchNext() async {
    // 현재 세대의 요청이 이미 진행 중이면 스킵. 세대가 바뀐(_clearAndFetch) 경우엔
    // 이전 요청이 곧 취소로 끝나므로 새 요청을 진행한다.
    if (_activeFetchGeneration == _generation) return;
    if (!_hasMore) return;

    final wasFirstPage = _page == 0;
    final myGeneration = _generation;
    _activeFetchGeneration = myGeneration;
    final token = _fetchToken;

    // 아이템이 없을 때만 전체 로딩 스피너 표시 (items가 있으면 기존 데이터 유지)
    if (wasFirstPage) {
      _isLoading = _items.isEmpty;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    safeNotify();

    try {
      final result = await withCancelScope(
        token,
        () => _service.fetchPreviews(
          page: _page,
          size: _size,
          includeEnded: true,
          genres: _selectedGenres.toList(),
          regions: _selectedRegions.toList(),
          ageRestrictions: _selectedAgeRestrictions.toList(),
        ),
      );
      // 응답 도착 전 필터가 바뀌어 이 요청이 무효화됐으면 결과를 버림
      if (myGeneration != _generation) return;

      // page 0은 기존 목록을 교체(새로고침·필터변경), 그 외에는 이어붙임(더 불러오기)
      if (wasFirstPage) _items.clear();
      _refreshError = null;
      _items.addAll(result.items);
      _cachedItems = List.unmodifiable(_items);
      _hasMore = result.hasMore;
      _page += 1;
      if (wasFirstPage) _staleness.markLoaded();
    } catch (e) {
      // 필터 변경으로 취소된 요청 — 새 요청이 이미 진행 중이므로 조용히 무시
      if (isRequestCancelled(e)) return;
      if (myGeneration != _generation) return;
      debugPrint('festival preview error: $e');
      if (_items.isEmpty) {
        _error = e;
      } else {
        // 기존 데이터 유지, 새로고침/더 불러오기 실패 알림 (snackbar용 일회성 플래그)
        // — wasFirstPage 여부와 무관하게 항상 알려야 "더 불러오기"만 조용히
        // 실패하는 비대칭을 피할 수 있음
        _refreshError = fetchFailureText(e);
      }
    } finally {
      // 이 fetch가 여전히 최신 세대라면 로딩 상태를 정리한다. 세대가 바뀌었다면
      // 이미 새 fetchNext가 진행 중이므로 그쪽이 소유한다.
      if (_activeFetchGeneration == myGeneration) {
        _activeFetchGeneration = null;
        _isLoading = false;
        _isLoadingMore = false;
        safeNotify();
      }
    }
  }

  @override
  void dispose() {
    _filterDebounce.dispose();
    _fetchToken.cancel();
    super.dispose();
  }
}
