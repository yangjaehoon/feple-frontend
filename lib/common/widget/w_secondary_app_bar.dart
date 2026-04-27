import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 서브 페이지(뒤로가기 버튼이 있는 화면)용 공통 AppBar.
/// backgroundColor: colors.appBarColor, foregroundColor: Colors.white 를 자동 적용합니다.
class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final double? elevation;

  const SecondaryAppBar({super.key, required this.title, this.actions, this.elevation});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      title: Text(title),
      backgroundColor: colors.appBarColor,
      foregroundColor: Colors.white,
      elevation: elevation,
      actions: actions,
    );
  }
}
