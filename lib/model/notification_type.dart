enum NotificationType {
  newFestival('NEW_FESTIVAL'),
  certApproved('CERT_APPROVED'),
  certRejected('CERT_REJECTED'),
  newComment('NEW_COMMENT'),
  festivalReminder('FESTIVAL_REMINDER'),
  songRequestApproved('SONG_REQUEST_APPROVED'),
  songRequestRejected('SONG_REQUEST_REJECTED'),
  artistSuggestionProcessed('ARTIST_SUGGESTION_PROCESSED'),
  adminBroadcast('ADMIN_BROADCAST');

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

  bool get isCertType =>
      this == NotificationType.certApproved ||
      this == NotificationType.certRejected;

  bool get isCommentType => this == NotificationType.newComment;

  bool get isFestivalFilterType =>
      this == NotificationType.newFestival ||
      this == NotificationType.festivalReminder ||
      this == NotificationType.songRequestApproved ||
      this == NotificationType.songRequestRejected ||
      this == NotificationType.artistSuggestionProcessed;
}
