import 'package:flutter/material.dart';

import '../constant/app_dimensions.dart';
import '../dart/extension/context_extension.dart';

/// 로그인/회원가입 계열 화면(s_login, s_signup, s_age_gate, s_forgot_password,
/// s_verify_email)에서 반복되던 타이틀/서브타이틀 스타일을 통일한다.
class AuthTitleText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;

  const AuthTitleText(this.text, {super.key, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: AppDimens.fontSizeDisplay,
        fontWeight: FontWeight.w800,
        color: context.appColors.textTitle,
        letterSpacing: -0.5,
      ),
    );
  }
}

class AuthSubtitleText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final double? height;

  const AuthSubtitleText(this.text, {super.key, this.textAlign, this.height});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: AppDimens.fontSizeMd,
        color: context.appColors.textSecondary,
        fontWeight: FontWeight.w500,
        height: height,
      ),
    );
  }
}
