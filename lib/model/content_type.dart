/// 딥링크/알림이 가리킬 수 있는 콘텐츠 종류.
/// `resolveContentDestination`(lib/screen/notification/notification_destination.dart)의
/// 라우팅 키로 쓰인다.
enum ContentType {
  festival('festival'),
  post('post'),
  artist('artist');

  const ContentType(this.pathSegment);

  /// `feple://<pathSegment>/<id>` 딥링크의 host 부분.
  final String pathSegment;

  /// 공유 텍스트에 넣을 딥링크. 커스텀 URL 스킴이라 앱이 설치된 기기에서만
  /// 동작한다(`DeepLinkHandler` 참고) — 도메인이 생기면 https 링크로 교체할 것.
  Uri deepLink(int id) => Uri(scheme: 'feple', host: pathSegment, path: '/$id');
}
