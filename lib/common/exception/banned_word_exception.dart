class BannedWordException implements Exception {
  final String field; // 'title' or 'content'

  const BannedWordException(this.field);

  @override
  String toString() => 'BannedWordException(field: $field)';
}
