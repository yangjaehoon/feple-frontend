import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 홈에서 펼쳐 보는 목록 화면(찜한 페스티벌 / 팔로우 아티스트)의 공통 앱바 —
/// 뒤로가기 + 제목 + (선택) 순서 변경 설정 버튼.
///
/// 공용 [SecondaryAppBar]를 쓰지 않는 이유: 그쪽은 appBarColor(라이트 테마에서
/// skyBlue) 배경을 쓰는데 이 두 화면은 surface 배경으로 디자인돼 있다. 색을
/// 바꾸는 건 별도 디자인 결정이라, 여기서는 두 화면에 복제돼 있던 마크업만 묶는다.
class ReorderScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// null이면 설정 버튼을 표시하지 않는다(순서 저장이 불가능하거나 대상이 없는 경우).
  final VoidCallback? onOpenSettings;

  const ReorderScreenAppBar({
    super.key,
    required this.title,
    this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      leading: IconButton(
        tooltip: 'back'.tr(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: colors.textTitle,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXxl,
          fontWeight: FontWeight.w700,
          color: colors.textTitle,
        ),
      ),
      actions: [
        if (onOpenSettings != null)
          IconButton(
            tooltip: 'settings'.tr(),
            icon: Icon(
              Icons.settings_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
            onPressed: onOpenSettings,
          ),
      ],
    );
  }
}
