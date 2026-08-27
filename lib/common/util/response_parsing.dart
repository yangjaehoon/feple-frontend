import 'dart:convert';

/// HTTP 응답 바디에서 리스트를 꺼낸다.
/// 서버가 순수 배열(`[...]`)을 주든 Spring `Page`(`{"content": [...]}`)로
/// 감싸 주든 동일하게 처리하고, 그 외 형태면 빈 리스트를 반환한다.
/// (예전엔 `data as List` 하드 캐스트라 래핑된 응답/에러 객체에서 즉시 크래시)
List<dynamic> extractJsonList(dynamic data) {
  final decoded = data is String ? _tryDecode(data) : data;
  if (decoded is List) return decoded;
  if (decoded is Map) {
    final inner = decoded['content'] ?? decoded['data'] ?? decoded['items'];
    if (inner is List) return inner;
  }
  return const [];
}

/// HTTP 응답 바디를 `Map<String, dynamic>`으로 정규화한다.
/// 문자열로 온 JSON은 디코드하고, Map이 아니면 [FormatException]을 던진다.
Map<String, dynamic> extractJsonMap(dynamic data) {
  final decoded = data is String ? jsonDecode(data) : data;
  if (decoded is! Map<String, dynamic>) {
    throw FormatException(
      'Unexpected response type: ${decoded.runtimeType}',
    );
  }
  return decoded;
}

dynamic _tryDecode(String s) {
  try {
    return jsonDecode(s);
  } catch (_) {
    return s;
  }
}
