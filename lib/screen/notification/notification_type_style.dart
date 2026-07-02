export 'package:feple/model/notification_type.dart';

import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:feple/model/notification_type.dart';

extension NotificationTypeStyle on NotificationType {
  IconData get iconData {
    switch (this) {
      case NotificationType.certApproved:               return Icons.verified_rounded;
      case NotificationType.certRejected:               return Icons.cancel_outlined;
      case NotificationType.newComment:                 return Icons.chat_bubble_rounded;
      case NotificationType.newReply:                   return Icons.reply_rounded;
      case NotificationType.postLiked:                  return Icons.favorite_rounded;
      case NotificationType.postDeletedByAdmin:         return Icons.delete_outline_rounded;
      case NotificationType.festivalReminder:           return Icons.event_rounded;
      case NotificationType.newFestival:                return Icons.festival_rounded;
      case NotificationType.songRequestApproved:        return Icons.music_note_rounded;
      case NotificationType.songRequestRejected:        return Icons.music_off_rounded;
      case NotificationType.artistSuggestionProcessed:  return Icons.person_add_rounded;
      case NotificationType.adminBroadcast:             return Icons.campaign_rounded;
    }
  }

  Color iconColor(AbstractThemeColors colors) {
    switch (this) {
      case NotificationType.certApproved:               return colors.certRingColor;
      case NotificationType.certRejected:               return colors.textSecondary;
      case NotificationType.newComment:                 return colors.activate;
      case NotificationType.newReply:                   return colors.activate;
      case NotificationType.postLiked:                  return colors.certRingColor;
      case NotificationType.festivalReminder:           return AppColors.notificationReminder;
      case NotificationType.newFestival:                return colors.certRingColor;
      case NotificationType.songRequestApproved:        return colors.certRingColor;
      case NotificationType.songRequestRejected:        return AppColors.errorRed;
      case NotificationType.artistSuggestionProcessed:  return colors.activate;
      case NotificationType.postDeletedByAdmin:         return colors.textSecondary;
      case NotificationType.adminBroadcast:             return colors.accentColor;
    }
  }
}
