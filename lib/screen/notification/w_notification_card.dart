import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/notification/notification_type_style.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;
  final bool isLoading;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TapScale(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: AppDimens.animQuick,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _buildCardDecoration(colors),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconBadge(colors),
            const SizedBox(width: 12),
            Expanded(child: _buildTextContent(context, colors)),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.activate,
                  ),
                ),
              )
            else if (!item.read)
              _buildUnreadDot(colors),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(AbstractThemeColors colors) {
    return BoxDecoration(
      color: item.read
          ? colors.surface
          : Color.alphaBlend(colors.activate.withValues(alpha: 0.10), colors.surface),
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
      border: Border.all(
        color: item.read
            ? colors.listDivider
            : colors.activate.withValues(alpha: 0.35),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.cardShadow.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildIconBadge(AbstractThemeColors colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (item.type?.iconColor(colors) ?? colors.certRingColor).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        item.type?.iconData ?? Icons.festival_rounded,
        color: item.type?.iconColor(colors) ?? colors.certRingColor,
        size: 20,
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, AbstractThemeColors colors) {
    final isEnglish = context.isEnglish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.displayTitle(isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.displayBody(isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            color: colors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          item.relativeTime(!isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxs,
            color: colors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadDot(AbstractThemeColors colors) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 4, left: 8),
      decoration: BoxDecoration(
        color: colors.certRingColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
