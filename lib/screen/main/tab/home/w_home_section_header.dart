import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.onExpand,
    this.trailing,
  });

  final String title;
  final VoidCallback? onExpand;
  /// [onExpand]이 없을 때 헤더 우측에 표시할 임의 위젯 (설정 아이콘 등)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasTrailing = onExpand != null || trailing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, hasTrailing ? 8 : 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: colors.sectionBarColor,
              borderRadius: BorderRadius.circular(AppDimens.barRadius),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppDimens.fontSizeXxl,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onExpand != null) ...[
            IconButton(
              tooltip: 'see_all'.tr(),
              icon: Icon(Icons.arrow_forward_ios_rounded,
                  color: colors.textSecondary, size: 16),
              onPressed: onExpand,
            ),
          ] else if (trailing != null) ...[
            const Spacer(),
            trailing!,
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
