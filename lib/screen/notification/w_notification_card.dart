import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/notification/notification_type.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animQuick,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _buildCardDecoration(colors),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconBadge(colors),
            const SizedBox(width: 12),
            Expanded(child: _buildTextContent(colors)),
            if (!item.read) _buildUnreadDot(colors),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(AbstractThemeColors colors) {
    return BoxDecoration(
      color: item.read
          ? colors.surface
          : colors.certRingColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
      border: Border.all(
        color: item.read
            ? colors.listDivider
            : colors.certRingColor.withValues(alpha: 0.3),
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
        color: _iconColor(item.type, colors).withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
          item.type?.iconData ?? Icons.festival_rounded,
          color: _iconColor(item.type, colors), size: 20),
    );
  }

  Widget _buildTextContent(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.body,
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.formattedDate != null) ...[
          const SizedBox(height: 4),
          Text(
            item.formattedDate!,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
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

  Color _iconColor(NotificationType? type, AbstractThemeColors colors) {
    switch (type) {
      case NotificationType.certApproved:               return colors.certRingColor;
      case NotificationType.certRejected:               return colors.textSecondary;
      case NotificationType.newComment:                 return colors.activate;
      case NotificationType.festivalReminder:           return AppColors.notificationReminder;
      case NotificationType.songRequestApproved:        return Colors.green;
      case NotificationType.songRequestRejected:        return Colors.redAccent;
      case NotificationType.artistSuggestionProcessed: return colors.activate;
      default:                                          return colors.certRingColor;
    }
  }
}
