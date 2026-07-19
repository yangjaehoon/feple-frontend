import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 로그인/회원가입 화면 하단 "로그인에 문제가 있나요? 문의하기" 링크.
class SupportLinkRow extends StatelessWidget {
  static const _supportUrl = 'https://open.kakao.com/o/guLhbJki';

  const SupportLinkRow({super.key});

  Future<void> _openSupport(BuildContext context) async {
    final uri = Uri.parse(_supportUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) context.showErrorSnackbar('link_open_failed'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'login_trouble'.tr(),
          style: TextStyle(color: themeColors.textSecondary, fontSize: AppDimens.fontSizeSm),
        ),
        TextButton(
          onPressed: () => _openSupport(context),
          style: TextButton.styleFrom(
            foregroundColor: themeColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            'contact_support'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: themeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
