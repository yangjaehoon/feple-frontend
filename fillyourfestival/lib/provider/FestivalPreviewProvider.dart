import 'package:flutter/material.dart';
import 'package:fast_app_base/network/dio_client.dart';

import '../model/FestivalPreview.dart';

class FestivalPreviewProvider extends ChangeNotifier {

  FestivalPreviewProvider() {
    refresh();
  }

  final List<FestivalPreview> _items = [];

  List<FestivalPreview> get items => List.unmodifiable(_items);

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
      final resp = await DioClient.dio.get(
        '/festivals',
        queryParameters: {'page': _page, 'size': _size},
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
