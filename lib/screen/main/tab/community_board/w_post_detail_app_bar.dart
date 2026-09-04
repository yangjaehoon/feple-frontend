import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:flutter/material.dart';

/// 게시글 상세 화면 상단바 + 우측 더보기 메뉴.
/// 본인 글이면 수정/공유/삭제, 아니면 공유/신고/차단.
/// 선택 값('edit'|'delete'|'report'|'block'|'share')을 [onSelected]로 넘긴다.
class PostDetailAppBar extends StatelessWidget {
  final String title;
  final bool isOwn;
  final ValueChanged<String> onSelected;

  const PostDetailAppBar({
    super.key,
    required this.title,
    required this.isOwn,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SecondaryAppBar(
      title: title,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: onSelected,
          itemBuilder: (_) => _items(colors),
          color: colors.surface,
          shadowColor: colors.cardShadow.withValues(alpha: 0.18),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.shapeDialog),
          ),
          position: PopupMenuPosition.under,
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _items(AbstractThemeColors colors) {
    PopupMenuItem<String> item(
      String value,
      IconData icon,
      String label, {
      bool danger = false,
    }) =>
        buildPopupMenuItem(
          value: value,
          icon: icon,
          label: label,
          colors: colors,
          danger: danger,
          height: 48,
          iconSize: 19,
          spacing: 12,
          fontSize: AppDimens.fontSizeMd,
          fontWeight: FontWeight.w500,
        );

    if (isOwn) {
      return [
        item('edit', Icons.edit_outlined, 'edit_post'.tr()),
        item('share', Icons.share_outlined, 'share'.tr()),
        const PopupMenuDivider(height: 1),
        item('delete', Icons.delete_outline_rounded, 'delete_post'.tr(),
            danger: true),
      ];
    }
    return [
      item('share', Icons.share_outlined, 'share'.tr()),
      const PopupMenuDivider(height: 1),
      item('report', Icons.flag_outlined, 'report_post'.tr(), danger: true),
      const PopupMenuDivider(height: 1),
      item('block', Icons.block_rounded, 'block_user'.tr(), danger: true),
    ];
  }
}
