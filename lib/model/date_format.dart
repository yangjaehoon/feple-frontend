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
