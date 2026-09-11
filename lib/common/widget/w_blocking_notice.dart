import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_icon_circle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:flutter/material.dart';

/// 앱 진입을 막고 전체 화면으로 안내만 보여주는 화면(점검 중 / 강제 업데이트).
/// 뒤로가기로 빠져나갈 수 없다.
class BlockingNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  /// 선택적 보조 액션(예: 점검 화면의 "다시 시도").
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const BlockingNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rs = ResponsiveSize(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.backgroundMain,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  IconCircle(icon: icon, sizeAt390: 76),
                  SizedBox(height: rs.h(20)),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeDisplay,
                      fontWeight: FontWeight.w800,
                      color: colors.textTitle,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: rs.h(10)),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      color: colors.textSecondary,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: rs.h(28)),
                  LoadingButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                    backgroundColor: colors.activate,
                  ),
                  if (secondaryLabel != null) ...[
                    SizedBox(height: rs.h(8)),
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(
                        secondaryLabel!,
                        style: TextStyle(
                          fontSize: AppDimens.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
