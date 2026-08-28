import 'dart:async' show unawaited;

import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/common/util/response_parsing.dart';
import 'package:feple/model/spring_page.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/cache_fallback_fetcher.dart';
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

    // 캐시 폴백 시 hasMore는 알 수 없어 false로 취급 — parse가 호출될 때만 갱신됨
    var hasMore = false;
    final items = await fetchWithCacheFallback<FestivalPreview>(
      request: () => DioClient.dio.get('/festivals/page', queryParameters: params),
      parse: (data) {
        final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
        hasMore = springPageHasMore(map['page'] as Map<String, dynamic>?);
        return extractJsonList(data)
            .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      // 필터 없는 첫 페이지만 캐시 (오프라인 폴백용) — 응답 지연을 막기 위해 fire-and-forget
      save: (items) async {
        if (isDefaultList) unawaited(_cache.savePreviewList(items));
      },
      load: () => isDefaultList ? _cache.loadPreviewList() : Future.value(null),
    );
    return FestivalPreviewPage(items: items, hasMore: hasMore);
  }

  Future<FestivalModel> fetchById(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId');
    return FestivalModel.fromJson(extractJsonMap(response.data));
  }

  Future<List<FestivalModel>> fetchAll() async {
    final response = await DioClient.dio.get('/festivals');
    return response.toModelList(FestivalModel.fromJson);
  }

}
