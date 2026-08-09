import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 설정류 화면(설정/알림 설정 등)에서 반복되는 한 줄 항목
/// (아이콘 + 라벨 + trailing) — 탭 가능하면 [onTap], 스위치 등 커스텀
/// trailing이 필요하면 [trailing]을 넘긴다.
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = isDestructive ? colors.error : colors.activate;
    final textColor = isDestructive ? colors.error : colors.textTitle;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeLg,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class SettingsItemDivider extends StatelessWidget {
  const SettingsItemDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 50,
      color: context.appColors.listDivider,
    );
  }
}
