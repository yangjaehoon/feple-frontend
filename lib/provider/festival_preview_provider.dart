import 'package:flutter/material.dart';
import 'package:feple/network/dio_client.dart';

import '../model/festival_preview.dart';

class FestivalPreviewProvider extends ChangeNotifier {

  FestivalPreviewProvider() {
    refresh();
  }

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
      final Map<String, dynamic> params = {'page': _page, 'size': _size};
      if (_selectedGenres.isNotEmpty) {
        params['genres'] = _selectedGenres.toList();
      }
      if (_selectedRegions.isNotEmpty) {
        params['regions'] = _selectedRegions.toList();
      }

      final resp = await DioClient.dio.get(
        '/festivals',
        queryParameters: params,
      );

      final decoded = resp.data;
      final List<dynamic> list =
          decoded is List ? decoded : (decoded['content'] as List<dynamic>);

      final newItems = list
          .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
          .toList();

      _items.addAll(newItems);

      if (newItems.length < _size) _hasMore = false;
      _page += 1;
    } catch (e) {
      _error = '페스티벌 목록을 불러오지 못했어요: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
