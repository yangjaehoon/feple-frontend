import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:feple/service/festival_service.dart';

import '../model/festival_preview.dart';

class FestivalPreviewProvider extends ChangeNotifier {
  FestivalPreviewProvider(this._service) {
    refresh();
  }

  final FestivalService _service;

  final List<FestivalPreview> _items = [];
  List<FestivalPreview> get items => List.unmodifiable(_items);

  Set<String> _selectedGenres = {};
  Set<String> _selectedRegions = {};
  Set<String> _selectedAgeRestrictions = {};
  Set<String> get selectedGenres => Set.unmodifiable(_selectedGenres);
  Set<String> get selectedRegions => Set.unmodifiable(_selectedRegions);
  Set<String> get selectedAgeRestrictions => Set.unmodifiable(_selectedAgeRestrictions);

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  String? _error;
  String? get error => _error;
  int _page = 0;
  final int _size = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _disposed = false;

  DateTime? _loadedAt;
  static const _staleAfter = Duration(minutes: 5);
  bool get _isStale =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > _staleAfter;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    _clearAndFetch();
  }

  void toggleRegion(String region) {
    if (_selectedRegions.contains(region)) {
      _selectedRegions.remove(region);
    } else {
      _selectedRegions.add(region);
    }
    _clearAndFetch();
  }

  void toggleAgeRestriction(String ageRestriction) {
    if (_selectedAgeRestrictions.contains(ageRestriction)) {
      _selectedAgeRestrictions.remove(ageRestriction);
    } else {
      _selectedAgeRestrictions.add(ageRestriction);
    }
    _clearAndFetch();
  }

  void clearFilters() {
    _selectedGenres = {};
    _selectedRegions = {};
    _selectedAgeRestrictions = {};
    _clearAndFetch();
  }

  // 필터 변경 시: 즉시 목록 비우고 재요청
  void _clearAndFetch() {
    _items.clear();
    _page = 0;
    _hasMore = true;
    _error = null;
    _safeNotify();
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

    // 아이템이 없을 때만 전체 로딩 스피너 표시 (items가 있으면 기존 데이터 유지)
    if (_page == 0) {
      _isLoading = _items.isEmpty;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    _safeNotify();

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
      if (_page == 0) _items.clear();
      _items.addAll(newItems);
      if (newItems.length < _size) _hasMore = false;
      _page += 1;
      if (_page == 1) _loadedAt = DateTime.now();
    } catch (e) {
      debugPrint('festival preview error: $e');
      // 기존 데이터가 있으면 에러 미표시 — 조용히 실패
      if (_items.isEmpty) _error = 'err_fetch_data'.tr();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      _safeNotify();
    }
  }
}
