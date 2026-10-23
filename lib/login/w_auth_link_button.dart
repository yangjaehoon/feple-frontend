import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 인증 화면의 텍스트 링크 버튼("비밀번호 찾기", "회원가입", "로그인") — 여백 없이
/// 문구 크기에 맞추되 탭 영역은 최소 크기로 확보한다.
class AuthLinkButton extends StatelessWidget {
  final String label;

  /// null이면 비활성화된다.
  final VoidCallback? onPressed;
  final FontWeight fontWeight;

  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.appColors.activate,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: fontWeight, fontSize: AppDimens.fontSizeMd),
      ),
    );
  }
}
