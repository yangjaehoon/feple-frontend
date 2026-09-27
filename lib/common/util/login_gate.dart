import 'package:feple/common/common.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 로그인 유도(확인 다이얼로그 + 로그인 화면)는 루트 네비게이터 기준 앱 전체에
// 하나만 진행돼야 한다 — 위젯별 상태가 아니라 모듈 전역 가드.
bool _loginFlowActive = false;

// 가드를 세우고, 다음 프레임에 바로 푼다. 그 프레임부터는 다이얼로그/화면이
// 원래 버튼을 덮어 재탭이 불가능하고, dismiss 없이 트리가 교체되는 경우에도
// 가드가 영구히 막히지 않는다. 따라서 실질적으로 막는 것은 "첫 프레임이 그려지기
// 전, 같은 배치에서 ensureLoggedIn/openLoginScreen이 중복 호출되는" 경우다.
void _beginLoginFlow() {
  _loginFlowActive = true;
  // addPostFrameCallback은 콜백만 큐에 넣고 프레임을 스케줄하지 않는다. 지금까지는
  // 바로 뒤의 Navigator.push가 프레임을 유발해 우연히 풀렸는데, 그 push가 예외로
  // 죽으면 콜백이 영구히 대기해 앱 전체의 로그인 게이트가 잠긴다(모든 게이트 동작이
  // 조용히 무반응). 프레임을 명시적으로 요청해 해제를 보장한다.
  WidgetsBinding.instance.ensureVisualUpdate();
  WidgetsBinding.instance.addPostFrameCallback((_) => _loginFlowActive = false);
}

/// 로그인 화면을 루트 네비게이터에 push한다. 게스트 유도 지점 여러 곳에서
/// 반복되던 코드 — 항상 이 헬퍼를 쓴다.
///
/// 로그인에 성공해 화면이 닫히면(`s_login.dart`의 `_completeLogin`) `true`를
/// 반환한다. 사용자가 로그인 없이 뒤로 가면, 또는 이미 다른 호출로 로그인
/// 유도가 진행 중이면 `false`.
Future<bool> openLoginScreen(BuildContext context) async {
  if (_loginFlowActive) return false;
  _beginLoginFlow();
  return _pushLoginScreen(context);
}

/// 가드를 거치지 않는 실제 push — 이미 진입 지점에서 가드를 통과한 흐름이 쓴다.
/// [ensureLoggedIn]이 [openLoginScreen]을 호출하면 사용자가 [로그인]을 누른 뒤에
/// 가드를 한 번 더 통과해야 해서, 그 사이 다른 게이트 호출이 가드를 다시 세우면
/// 로그인 화면이 열리지 않고 원래 동작이 조용히 버려진다.
Future<bool> _pushLoginScreen(BuildContext context) async {
  final loggedIn = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return loggedIn ?? false;
}

/// 로그인이 필요한 동작 앞에 둔다.
///
/// 로그인 상태면 `true`를 즉시 반환한다. 비로그인이면 먼저 "로그인이 필요해요"
/// 확인 다이얼로그를 띄우고, 사용자가 [로그인]을 누른 경우에만 로그인 화면을
/// 연다 — 게스트가 무심코 누른 버튼에 맥락 없이 로그인 화면이 덮이는 것을 막는다.
/// 로그인에 성공하면 `true`를 반환해 호출부가 원래 하려던 동작을 곧바로 이어서
/// 실행할 수 있게 한다(의도 보존). [취소]하거나 로그인 없이 뒤로 가면 `false`.
/// 호출부는 아래 형태로 쓴다 — 확인 다이얼로그와 로그인 화면을 거치는 동안 몇 초가
/// 지날 수 있어, 돌아온 뒤 `context`를 쓰기 전에 위젯 생존 확인이 필요하다.
/// ```dart
/// if (!await ensureLoggedIn(context)) return;
/// if (!mounted) return;            // State 밖이면 `if (!context.mounted) return;`
/// ```
Future<bool> ensureLoggedIn(BuildContext context) async {
  if (context.read<UserProvider>().currentUserId != null) return true;
  if (_loginFlowActive) return false;

  _beginLoginFlow();
  final confirmed = await showConfirmDialog(
    context,
    title: 'login_required_title'.tr(),
    content: 'login_required'.tr(),
    confirmLabel: 'login'.tr(),
    destructive: false,
    confirmKey: const Key('login_gate_confirm'),
  );
  if (!confirmed || !context.mounted) return false;
  // 다이얼로그가 열려 있는 동안 자동 로그인이 끝났을 수 있다(콜드스타트에서 트리는
  // 갱신 전에 이미 조작 가능하다) — 이미 로그인된 사용자에게 로그인 화면을 띄우는
  // 대신 원래 하려던 동작을 이어가게 한다.
  if (context.read<UserProvider>().currentUserId != null) return true;

  return _pushLoginScreen(context);
}
