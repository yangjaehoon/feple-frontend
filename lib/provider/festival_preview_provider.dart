import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/stale_tracker.dart';
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
      _selectedGenres.isNotEmpty || _selectedRegions.isNotEmpty || _selectedAgeRestrictions.isNotEmpty;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  String? _error;
  String? get error => _error;
  // page 0 refresh 실패 + 기존 아이템 있을 때 설정 — UI가 snackbar로 표시 후 clearRefreshError() 호출
  String? _refreshError;
  String? get refreshError => _refreshError;

  void clearRefreshError() => _refreshError = null;
  int _page = 0;
  final int _size = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final _staleness = StaleTracker(const Duration(minutes: 5));

  // 연속 필터 변경 시 마지막 변경 후 400ms 뒤에만 API 호출
  Timer? _filterDebounce;
  static const _filterDebounceDelay = Duration(milliseconds: 400);

  // 필터 변경으로 무효화된 요청의 응답이 늦게 도착해 최신 결과를 덮어쓰지 않도록 가드
  int _generation = 0;

  void _toggleInSet(Set<String> current, String value, void Function(Set<String>) assign) {
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
  void toggleAgeRestriction(String ageRestriction) =>
      _toggleInSet(_selectedAgeRestrictions, ageRestriction, (s) => _selectedAgeRestrictions = s);

  void clearFilters() {
    _selectedGenres = const {};
    _selectedRegions = const {};
    _selectedAgeRestrictions = const {};
    _scheduleFetch();
  }

  void _scheduleFetch() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(_filterDebounceDelay, _clearAndFetch);
    safeNotify(); // 칩 상태 즉시 반영
  }

  // 필터 변경 확정 후: 즉시 목록 비우고 재요청
  void _clearAndFetch() {
    // 이전 세대(진행 중이던 요청)를 무효화 — 그 응답이 나중에 와도 결과를 반영하지 않음
    _generation++;
    _items.clear();
    _cachedItems = const [];
    _page = 0;
    _hasMore = true;
    _error = null;
    // 진행 중이던 요청의 busy 플래그를 리셋해 새 요청이 가드에 막히지 않게 함
    _isLoading = false;
    _isLoadingMore = false;
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
    if (_isLoading || _isLoadingMore) return;
    if (!_hasMore) return;

    final wasFirstPage = _page == 0;
    final myGeneration = _generation;

    // 아이템이 없을 때만 전체 로딩 스피너 표시 (items가 있으면 기존 데이터 유지)
    if (wasFirstPage) {
      _isLoading = _items.isEmpty;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    safeNotify();

    try {
      final newItems = await _service.fetchPreviews(
        page: _page,
        size: _size,
        includeEnded: true,
        genres: _selectedGenres.toList(),
        regions: _selectedRegions.toList(),
        ageRestrictions: _selectedAgeRestrictions.toList(),
      );
      // 응답 도착 전 필터가 바뀌어 이 요청이 무효화됐으면 결과를 버림
      if (myGeneration != _generation) return;

      // page 0이면 기존 데이터를 새 데이터로 교체
      if (wasFirstPage) {
        _items.clear();
        _refreshError = null;
      }
      _items.addAll(newItems);
      _cachedItems = List.unmodifiable(_items);
      if (newItems.length < _size) _hasMore = false;
      _page += 1;
      if (wasFirstPage) _staleness.markLoaded();
    } catch (e) {
      if (myGeneration != _generation) return;
      debugPrint('festival preview error: $e');
      if (_items.isEmpty) {
        _error = 'err_fetch_data'.tr();
      } else {
        // 기존 데이터 유지, 새로고침/더 불러오기 실패 알림 (snackbar용 일회성 플래그)
        // — wasFirstPage 여부와 무관하게 항상 알려야 "더 불러오기"만 조용히
        // 실패하는 비대칭을 피할 수 있음
        _refreshError = 'err_fetch_data'.tr();
      }
    } finally {
      if (myGeneration == _generation) {
        _isLoading = false;
        _isLoadingMore = false;
        safeNotify();
      }
    }
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    super.dispose();
  }
}
