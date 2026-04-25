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
}
