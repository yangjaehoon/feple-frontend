import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 인증 폼(로그인·비밀번호 재설정)에서 필드 테두리 없이 텍스트로만 보여주는
/// 서버/인증 오류 한 줄 — 경고 아이콘 + 빨간 메시지.
class FormErrorText extends StatelessWidget {
  final String message;

  const FormErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final error = context.appColors.error;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: error, size: 14),
          const SizedBox(width: AppDimens.space4),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                color: error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
