import 'package:feple/model/user_model.dart';

/// 이메일 인증 화면(과 그 아래 회원가입 화면)이 pop으로 돌려주는 결과.
/// 뒤로가기처럼 아무것도 결정되지 않은 이탈은 결과 없이(`null`) 닫힌다.
///
/// 로그인 마무리(setUser·스택 정리)는 흐름의 맨 아래인 LoginScreen이 맡는다 —
/// 중간 화면이 `popUntil(isFirst)`로 스택을 직접 정리하면, 게스트 둘러보기 중
/// 루트 네비게이터에 LoginScreen이 push된 경로에서 게스트가 보고 있던 화면까지
/// 함께 사라지고 `openLoginScreen`의 `push<bool>`도 결과를 받지 못한다.
class AuthFlowResult {
  /// 이메일 인증까지 끝나 로그인할 수 있는 상태.
  const AuthFlowResult.verified(AppUser this.user);

  /// 계정 삭제·로그아웃으로 인증 흐름을 접었다 — 중간 화면은 자신도 함께 닫아
  /// 로그인 화면을 드러낸다.
  const AuthFlowResult.aborted() : user = null;

  /// 로그인할 사용자. 흐름을 접은 경우([AuthFlowResult.aborted]) null.
  final AppUser? user;
}
