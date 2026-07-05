class BannedWordException implements Exception {
  // 서버 응답의 data['field'] 값을 그대로 담는 자유 문자열
  // (예: 'title', 'content', 'bio' 등 — 고정된 값 목록이 아님)
  final String field;

  const BannedWordException(this.field);

  @override
  String toString() => 'BannedWordException(field: $field)';
}
