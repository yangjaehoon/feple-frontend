/// 서버가 준 ISO 8601 문자열을 [DateTime]으로 파싱한다. 값이 없거나 형식이
/// 잘못되면 epoch(1970-01-01 UTC)로 폴백한다 — 잘못된 한 건 때문에 목록 전체
/// 파싱이 예외로 실패하지 않도록.
DateTime parseServerDateTime(String? iso) =>
    DateTime.tryParse(iso ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// ISO 8601 문자열을 'yyyy.MM.dd' 형식으로 변환. 파싱 실패 시 원본 문자열, null이면 null 반환.
String? formatShortDate(String? iso) {
  if (iso == null) return null;
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
