import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 인증 흐름 화면(가입·이메일 인증·비밀번호 찾기)의 투명 앱바 — 제목 없이 뒤로가기만 둔다.
/// 제목·배경색이 있는 일반 서브 페이지용 앱바는 `SecondaryAppBar`.
class AuthBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 뒤로가기 동작. null이면 버튼이 비활성화된다(처리 중 이탈 방지).
  final VoidCallback? onBack;

  const AuthBackAppBar({super.key, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'back'.tr(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.appColors.textTitle,
          size: AppDimens.iconSizeLg,
        ),
        onPressed: onBack,
      ),
    );
  }
}
