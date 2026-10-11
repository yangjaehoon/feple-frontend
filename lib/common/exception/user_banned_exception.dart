/// 정지된 계정으로 로그인을 시도한 경우 (서버 403 `USER_BANNED`).
/// 로그인 화면은 일반 실패 문구 대신 정지 안내를 보여준다.
class UserBannedException implements Exception {
  @override
  String toString() => 'UserBannedException';
}
