import 'dart:async' show unawaited;

import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_cache_service.dart';

class FestivalService {
  final FestivalCacheService _cache;

  FestivalService(this._cache);

  Future<FestivalPreviewPage> fetchPreviews({
    required int page,
    required int size,
    required bool includeEnded,
    List<String> genres = const [],
    List<String> regions = const [],
    List<String> ageRestrictions = const [],
  }) async {
    final isDefaultList = page == 0 &&
        genres.isEmpty &&
        regions.isEmpty &&
        ageRestrictions.isEmpty;

    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
      'includeEnded': includeEnded,
    };
    if (genres.isNotEmpty) params['genres'] = genres;
    if (regions.isNotEmpty) params['regions'] = regions;
    if (ageRestrictions.isNotEmpty) params['ageRestrictions'] = ageRestrictions;

    try {
      final response = await DioClient.dio.get('/festivals/page', queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      final items = (data['content'] as List)
          .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
          .toList();
      final pageInfo = data['page'] as Map<String, dynamic>? ?? {};
      final pageNumber = (pageInfo['number'] as num?)?.toInt() ?? 0;
      final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
      final hasMore = pageNumber + 1 < totalPages;

      if (isDefaultList) {
        // 필터 없는 첫 페이지만 캐시 (오프라인 폴백용)
        unawaited(_cache.savePreviewList(items));
      }
      return FestivalPreviewPage(items: items, hasMore: hasMore);
    } catch (e) {
      if (isDefaultList && isOffline(e)) {
        final cached = await _cache.loadPreviewList();
        if (cached != null) return FestivalPreviewPage(items: cached, hasMore: false);
      }
      rethrow;
    }
  }

  Future<FestivalModel> fetchById(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId');
    return FestivalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FestivalModel>> fetchAll() async {
    final response = await DioClient.dio.get('/festivals');
    return response.toModelList(FestivalModel.fromJson);
  }

}
