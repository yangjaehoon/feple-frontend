import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/safe_change_notifier.dart';
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

  DateTime? _loadedAt;
  static const _staleAfter = Duration(minutes: 5);
  bool get _isStale =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > _staleAfter;

  // 연속 필터 변경 시 마지막 변경 후 400ms 뒤에만 API 호출
  Timer? _filterDebounce;
  static const _filterDebounceDelay = Duration(milliseconds: 400);

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
    if (!force && _items.isNotEmpty && !_isStale) return;
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

      // page 0이면 기존 데이터를 새 데이터로 교체
      if (wasFirstPage) {
        _items.clear();
        _refreshError = null;
      }
      _items.addAll(newItems);
      _cachedItems = List.unmodifiable(_items);
      if (newItems.length < _size) _hasMore = false;
      _page += 1;
      if (wasFirstPage) _loadedAt = DateTime.now();
    } catch (e) {
      debugPrint('festival preview error: $e');
      if (_items.isEmpty) {
        _error = 'err_fetch_data'.tr();
      } else if (wasFirstPage) {
        // 기존 데이터 유지, 새로고침 실패 알림 (snackbar용 일회성 플래그)
        _refreshError = 'err_fetch_data'.tr();
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      safeNotify();
    }
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    super.dispose();
  }
}
