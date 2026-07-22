import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 서브 페이지용 공통 앱바.
/// SafeArea + Container 방식으로 상태 표시줄 영역을 투명하게 유지합니다.
class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  /// 뒤로가기 버튼 탭 시 동작을 오버라이드. 미지정 시 기본값(Navigator.pop).
  /// PopScope로 이탈 확인을 거는 화면은 반드시 지정할 것 — 이 버튼은
  /// Navigator.pop을 직접 호출하는 imperative pop이라 PopScope(canPop:false)를
  /// 우회하므로, 지정하지 않으면 시스템 뒤로가기와 달리 확인 없이 바로 닫힘.
  final VoidCallback? onBackPressed;

  const SecondaryAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final onAppBar = colors.appBarIconColor;
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.appBarColor,
        child: Row(
          children: [
            IconButton(
              tooltip: 'back'.tr(),
              icon: Icon(Icons.arrow_back_ios_rounded, color: onAppBar),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: onAppBar,
                  fontSize: AppDimens.fontSizeTitle,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions != null)
              IconTheme(
                data: IconThemeData(color: onAppBar),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
          ],
        ),
      ),
    );
  }
}
