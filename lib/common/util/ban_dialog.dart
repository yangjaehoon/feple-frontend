import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_alert_dialog.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';

/// 계정이 정지된 것을 서버가 알려왔을 때(`DioClient.onUserBanned`) 안내하고
/// 로그아웃시킨다.
///
/// 위젯 트리 밖(인터셉터 콜백)에서 불리므로 [App.navigatorKey]의 컨텍스트를
/// 쓴다. 다이얼로그를 띄우지 못하는 상황(네비게이터 미마운트)이어도
/// **로그아웃은 반드시 실행한다** — 정지된 계정을 그대로 두면 안 된다.
Future<void> showBanDialog(UserProvider userProvider) async {
  // 정지된 계정은 요청마다 같은 응답을 받으므로 인터셉터가 연달아 부른다.
  if (_isShowing) return;
  _isShowing = true;
  try {
    final ctx = App.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) => buildAppAlertDialog(
          dialogCtx,
          title: 'account_banned_title'.tr(),
          content: 'account_banned_message'.tr(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('confirm'.tr()),
            ),
          ],
        ),
      );
    }
  } finally {
    _isShowing = false;
    if (userProvider.user != null) {
      await userProvider.logout();
    }
  }
}

bool _isShowing = false;
