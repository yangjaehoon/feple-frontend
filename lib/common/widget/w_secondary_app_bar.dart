import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 서브 페이지용 공통 앱바.
/// SafeArea + Container 방식으로 상태 표시줄 영역을 투명하게 유지합니다.
class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const SecondaryAppBar({
    super.key,
    required this.title,
    this.actions,
    double? elevation, // API 호환성 유지용, 미사용
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.appBarColor,
        child: Row(
          children: [
            IconButton(
              tooltip: 'back'.tr(),
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions != null)
              IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
          ],
        ),
      ),
    );
  }
}
