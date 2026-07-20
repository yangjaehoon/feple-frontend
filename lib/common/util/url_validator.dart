/// http(s) 스킴 + youtube 도메인인지 검증.
/// 서버에서 내려온 URL도 실제 실행(launchUrl) 직전에 재검증해
/// 신청 시점 검증을 우회한 값(다른 API 클라이언트, 관리자 입력 등)이
/// 임의 스킴으로 실행되는 것을 방지한다.
bool isValidYoutubeUrl(String url) {
  if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
  return url.contains('youtube.com') || url.contains('youtu.be');
}
