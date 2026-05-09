import 'package:flutter/material.dart';

enum NotificationType {
  newFestival('NEW_FESTIVAL'),
  certApproved('CERT_APPROVED'),
  certRejected('CERT_REJECTED'),
  newComment('NEW_COMMENT'),
  festivalReminder('FESTIVAL_REMINDER');

  const NotificationType(this.value);
  final String value;

  static NotificationType? fromValue(String? value) {
    if (value == null) return null;
    for (final type in NotificationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  bool get isFestivalType =>
      this == NotificationType.newFestival ||
      this == NotificationType.festivalReminder;

  IconData get iconData {
    switch (this) {
      case NotificationType.certApproved:     return Icons.verified_rounded;
      case NotificationType.certRejected:     return Icons.cancel_outlined;
      case NotificationType.newComment:       return Icons.chat_bubble_rounded;
      case NotificationType.festivalReminder: return Icons.event_rounded;
      case NotificationType.newFestival:      return Icons.festival_rounded;
    }
  }
}
