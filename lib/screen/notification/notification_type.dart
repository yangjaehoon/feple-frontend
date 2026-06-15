export 'package:feple/model/notification_type.dart';

import 'package:flutter/material.dart';
import 'package:feple/model/notification_type.dart';

extension NotificationTypeStyle on NotificationType {
  IconData get iconData {
    switch (this) {
      case NotificationType.certApproved:               return Icons.verified_rounded;
      case NotificationType.certRejected:               return Icons.cancel_outlined;
      case NotificationType.newComment:                 return Icons.chat_bubble_rounded;
      case NotificationType.festivalReminder:           return Icons.event_rounded;
      case NotificationType.newFestival:                return Icons.festival_rounded;
      case NotificationType.songRequestApproved:        return Icons.music_note_rounded;
      case NotificationType.songRequestRejected:        return Icons.music_off_rounded;
      case NotificationType.artistSuggestionProcessed:  return Icons.person_add_rounded;
      case NotificationType.adminBroadcast:             return Icons.campaign_rounded;
    }
  }
}
