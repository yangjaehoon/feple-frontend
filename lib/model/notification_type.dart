enum NotificationType {
  newFestival('NEW_FESTIVAL'),
  certApproved('CERT_APPROVED'),
  certRejected('CERT_REJECTED'),
  newComment('NEW_COMMENT'),
  newReply('NEW_REPLY'),
  postLiked('POST_LIKED'),
  postDeletedByAdmin('POST_DELETED_BY_ADMIN'),
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

  bool get isCommentType =>
      this == NotificationType.newComment ||
      this == NotificationType.newReply ||
      this == NotificationType.postLiked ||
      this == NotificationType.postDeletedByAdmin;

  bool get isFestivalFilterType =>
      this == NotificationType.newFestival ||
      this == NotificationType.festivalReminder ||
      this == NotificationType.songRequestApproved ||
      this == NotificationType.songRequestRejected ||
      this == NotificationType.artistSuggestionProcessed;

  bool get isSongRequestType =>
      this == NotificationType.songRequestApproved ||
      this == NotificationType.songRequestRejected;

  bool get isArtistNavigationType =>
      isSongRequestType || this == NotificationType.artistSuggestionProcessed;

  bool get hasFestivalNavigation => isFestivalType || isCertType;

  // 관리자 공지는 개별 삭제를 지원하지 않음 — 스와이프 삭제 UI 자체를 막아서
  // "삭제했는데 다시 나타나는" 혼란을 방지 (서버가 삭제를 반영하지 않기 때문)
  bool get isDismissible => this != NotificationType.adminBroadcast;
}
