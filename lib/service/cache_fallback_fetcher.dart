import 'package:dio/dio.dart';
import 'package:feple/common/util/dio_error_helper.dart';

/// GET 요청 → 캐시 저장, 오프라인이면서 캐시가 있으면 캐시로 폴백.
/// [FestivalDetailService]/[FestivalService]가 각자 구현하던 동일한
/// 오프라인 폴백 패턴을 공유한다.
Future<List<T>> fetchWithCacheFallback<T>({
  required Future<Response> Function() request,
  required List<T> Function(dynamic data) parse,
  required Future<void> Function(List<T> items) save,
  required Future<List<T>?> Function() load,
}) async {
  try {
    final response = await request();
    final items = parse(response.data);
    await save(items);
    return items;
  } catch (e) {
    if (isOffline(e)) {
      final cached = await load();
      if (cached != null) return cached;
    }
    rethrow;
  }
}
