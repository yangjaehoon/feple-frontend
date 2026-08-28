/// `fromJson`에서 서버 응답 필드를 안전하게 꺼내기 위한 접근자.
///
/// 값이 없거나 타입이 다르면 예외 대신 지정한 기본값(또는 null)으로 폴백한다 —
/// 잘못된 필드 하나가 목록 전체 파싱을 무너뜨리지 않도록. 서버가 숫자를 문자열로
/// 주는(`"5"`) 느슨한 응답도 흡수한다.
///
/// 예전엔 모델마다 `(json['x'] as num?)?.toInt() ?? 0`,
/// `json['x'] as String? ?? ''` 류의 방어 관용구가 제각각 반복됐다.
extension JsonReader on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    return value is String ? value : fallback;
  }

  String? strOrNull(String key) {
    final value = this[key];
    return value is String ? value : null;
  }

  int integer(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  int? intOrNull(String key) {
    final value = this[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double dbl(String key, [double fallback = 0]) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  double? dblOrNull(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool boolean(String key, [bool fallback = false]) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  /// 문자열 리스트. List가 아니거나 없으면 빈 리스트(불변).
  List<String> stringList(String key) {
    final value = this[key];
    return value is List ? value.whereType<String>().toList() : const [];
  }

  /// 객체 리스트(중첩 fromJson용). List가 아니거나 없으면 빈 리스트(불변).
  List<Map<String, dynamic>> objectList(String key) {
    final value = this[key];
    return value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  /// 중첩 객체 하나. Map이 아니거나 없으면 null.
  Map<String, dynamic>? objectOrNull(String key) {
    final value = this[key];
    return value is Map<String, dynamic> ? value : null;
  }

  /// ISO 8601 문자열 → DateTime. 형식이 잘못됐거나 없으면 null.
  DateTime? dateTimeOrNull(String key) {
    final value = this[key];
    return value is String ? DateTime.tryParse(value) : null;
  }
}
