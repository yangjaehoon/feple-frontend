import 'json_reader.dart';

/// Spring Data Page 응답의 `page` 메타 정보에서 다음 페이지 존재 여부를 계산한다.
bool springPageHasMore(Map<String, dynamic>? pageInfo) {
  final info = pageInfo ?? const <String, dynamic>{};
  final pageNumber = info.integer('number');
  final totalPages = info.integer('totalPages', 1);
  return pageNumber + 1 < totalPages;
}
