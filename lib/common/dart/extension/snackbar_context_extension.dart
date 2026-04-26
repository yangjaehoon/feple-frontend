import 'package:feple/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

extension SnackbarContextExtension on BuildContext {
  /// 기본 (중립) 스낵바
  void showSnackbar(String message, {Widget? extraButton}) {
    _show(this, message, _SnackType.neutral, extraButton: extraButton);
  }

  /// 성공 스낵바 (초록)
  void showSuccessSnackbar(String message) {
    _show(this, message, _SnackType.success);
  }

  /// 에러 스낵바 (빨강)
  void showErrorSnackbar(
    String message, {
    @Deprecated('Use showErrorSnackbar without bgColor') Color bgColor = AppColors.salmon,
    double bottomMargin = 0,
  }) {
    _show(this, message, _SnackType.error);
  }

  /// 정보 스낵바 (파랑)
  void showInfoSnackbar(String message) {
    _show(this, message, _SnackType.info);
  }
}

enum _SnackType { success, error, info, neutral }

void _show(
  BuildContext context,
  String message,
  _SnackType type, {
  Widget? extraButton,
}) {
  late Color bg;
  late IconData icon;

  switch (type) {
    case _SnackType.success:
      bg = AppColors.successGreen;
      icon = Icons.check_circle_rounded;
      break;
    case _SnackType.error:
      bg = AppColors.errorRed;
      icon = Icons.error_rounded;
      break;
    case _SnackType.info:
      bg = AppColors.infoBlue;
      icon = Icons.info_rounded;
      break;
    case _SnackType.neutral:
      bg = AppColors.offlineBannerBg;
      icon = Icons.notifications_rounded;
      break;
  }

  final snackBar = SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    duration: const Duration(milliseconds: 2800),
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          if (extraButton != null) ...[const SizedBox(width: 8), extraButton],
        ],
      ),
    ),
  );

  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(snackBar);
}
