/// 외부 인증(Firebase/카카오/Apple/Google) 결과를 앱 자체 JWT로 교환하는
/// 과정이 실패했음을 나타낸다. 서버 오류, 응답 스키마 불일치, Firebase
/// credential/토큰 누락 등을 하나의 타입으로 통일한다 —
/// UI는 이 예외를 고정 i18n 키(`login_failed`)로만 표시하고, [reason]은
/// 로깅/디버깅용이라 사용자에게 노출하지 않는다.
class AuthExchangeException implements Exception {
  final String reason;

  AuthExchangeException(this.reason);

  @override
  String toString() => 'AuthExchangeException: $reason';
}
