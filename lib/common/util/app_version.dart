// 세맨틱 버전("1.2.3") 비교 유틸.
//
// `package_info_plus`의 `PackageInfo.version`(빌드 번호 없는 "1.2.3" 형태)과
// 서버가 내려준 최소/최신 버전 문자열을 비교하는 데 쓴다.

/// 버전 문자열을 정수 세그먼트 리스트로 파싱한다.
///
/// - 빌드/프리릴리스 메타데이터(`+`, `-` 이후)는 무시한다.
/// - 숫자가 아닌 세그먼트가 섞여 있으면 형식 오류로 보고 null을 반환한다.
/// - 숫자 세그먼트가 하나도 없으면 null.
List<int>? parseVersion(String? raw) {
  if (raw == null) return null;
  final core = raw.trim().split(RegExp(r'[+-]')).first;
  if (core.isEmpty) return null;

  final segments = <int>[];
  for (final part in core.split('.')) {
    final parsed = int.tryParse(part.trim());
    if (parsed == null || parsed < 0) return null;
    segments.add(parsed);
  }
  return segments.isEmpty ? null : segments;
}

/// [current]가 [minimum]보다 낮은지 여부.
///
/// 둘 중 하나라도 형식이 올바르지 않으면 `false`를 반환한다 —
/// 파싱 실패로 사용자를 강제 업데이트 화면에 가두지 않기 위한 fail-open.
bool isVersionBelow(String current, String minimum) {
  final currentSegments = parseVersion(current);
  final minimumSegments = parseVersion(minimum);
  if (currentSegments == null || minimumSegments == null) return false;
  return _compareSegments(currentSegments, minimumSegments) < 0;
}

int _compareSegments(List<int> a, List<int> b) {
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final left = i < a.length ? a[i] : 0;
    final right = i < b.length ? b[i] : 0;
    if (left != right) return left - right;
  }
  return 0;
}
