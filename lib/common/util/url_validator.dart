// 서버에서 내려온 URL도 실제 실행(launchUrl) 직전에 재검증한다.
// 평문 HTTP 전송 특성상 응답이 MITM으로 조작될 수 있고, 관리자 입력·다른
// API 클라이언트가 신청 시점 검증을 우회했을 수도 있으므로, 위험한 스킴
// (javascript:, intent://, tel:, file: 등)이 그대로 실행되는 것을 막는다.

const _youtubeHosts = {
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtube-nocookie.com',
  'www.youtube-nocookie.com',
  'youtu.be',
};

/// http(s) 스킴 + 실제 유튜브 호스트인지 검증.
/// (`url.contains('youtube.com')` 방식은 `https://youtube.com.evil.com` 같은
/// 값을 통과시켰음 — 호스트를 파싱해 정확히 비교한다.)
bool isValidYoutubeUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return _youtubeHosts.contains(uri.host.toLowerCase());
}

/// 외부 브라우저/앱으로 열어도 안전한 일반 웹 링크인지 검증.
/// http/https 스킴 + 호스트가 있는 절대 URL만 허용한다.
bool isSafeExternalUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return uri.host.isNotEmpty;
}
