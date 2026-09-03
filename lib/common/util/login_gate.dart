import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 로그인이 필요한 동작 앞에 둔다.
///
/// 로그인 상태면 `true`를 반환한다. 비로그인이면 안내 스낵바(오른쪽에 '로그인'
/// 버튼 — 누르면 로그인 화면)를 띄우고 `false`를 반환한다. 호출부는
/// `if (!ensureLoggedIn(context)) return;` 형태로 쓴다.
bool ensureLoggedIn(BuildContext context, {String messageKey = 'login_required'}) {
  if (context.read<UserProvider>().currentUserId != null) return true;

  context.showInfoSnackbar(
    messageKey.tr(),
    extraButton: TextButton(
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'login'.tr(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: AppDimens.fontSizeMd,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
    ),
  );
  return false;
}
