/// 나이 확인에서 만 14세 미만으로 판정돼 서비스 이용이 차단된 경우.
/// 서버가 이미 계정을 파기했으며, UI는 되돌아갈 수 없는 안내 화면을 보여준다.
class AgeRestrictedException implements Exception {
  @override
  String toString() => 'AgeRestrictedException';
}
