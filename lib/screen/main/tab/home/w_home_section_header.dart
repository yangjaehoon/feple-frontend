import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.onExpand,
  });

  final String title;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, onExpand != null ? 8 : 20, 8),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
          if (onExpand != null) ...[
            const Spacer(),
            IconButton(
              tooltip: 'see_all'.tr(),
              icon: Icon(Icons.arrow_forward_ios_rounded,
                  color: colors.textSecondary, size: 16),
              onPressed: onExpand,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
