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
  Set<String> get selectedGenres => Set.unmodifiable(_selectedGenres);
  Set<String> get selectedRegions => Set.unmodifiable(_selectedRegions);

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

  void toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    refresh();
  }

  void toggleRegion(String region) {
    if (_selectedRegions.contains(region)) {
      _selectedRegions.remove(region);
    } else {
      _selectedRegions.add(region);
    }
    refresh();
  }

  void clearFilters() {
    _selectedGenres = {};
    _selectedRegions = {};
    refresh();
  }

  Future<void> refresh() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
    await fetchNext();
  }

  Future<void> fetchNext() async {
    if (_isLoading || _isLoadingMore) return;
    if (!_hasMore) return;

    _page == 0 ? _isLoading = true : _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final newItems = await _service.fetchPreviews(
        page: _page,
        size: _size,
        includeEnded: true,
        genres: _selectedGenres.toList(),
        regions: _selectedRegions.toList(),
      );

      _items.addAll(newItems);
      if (newItems.length < _size) _hasMore = false;
      _page += 1;
    } catch (e) {
      _error = 'err_fetch_data'.tr(args: [e.toString()]);
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
