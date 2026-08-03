/// Spring Data Page 응답의 `page` 메타 정보에서 다음 페이지 존재 여부를 계산한다.
bool springPageHasMore(Map<String, dynamic>? pageInfo) {
  final info = pageInfo ?? const {};
  final pageNumber = (info['number'] as num?)?.toInt() ?? 0;
  final totalPages = (info['totalPages'] as num?)?.toInt() ?? 1;
  return pageNumber + 1 < totalPages;
}
