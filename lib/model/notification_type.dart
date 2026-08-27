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
  adminBroadcast('ADMIN_BROADCAST'),
  adminPointGranted('ADMIN_POINT_GRANTED');

  const NotificationType(this.value);
  final String value;

  static NotificationType? fromValue(String? value) {
    if (value == null) return null;
    for (final type in NotificationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  // 모든 NotificationType이 반드시 속하는 배타적 1차 분류.
  // switch에 default가 없어 새 NotificationType 추가 시 컴파일 에러로 강제됨 —
  // 아래 boolean getter들은 전부 이 분류에서 파생되므로 값 하나만 추가하면
  // isXxxType들이 자동으로 올바르게 계산됨 (일일이 수정할 필요 없음)
  _NotificationCategory get _category => switch (this) {
        NotificationType.newFestival ||
        NotificationType.festivalReminder =>
          _NotificationCategory.festival,
        NotificationType.certApproved ||
        NotificationType.certRejected =>
          _NotificationCategory.cert,
        NotificationType.newComment ||
        NotificationType.newReply ||
        NotificationType.postLiked ||
        NotificationType.postDeletedByAdmin =>
          _NotificationCategory.comment,
        NotificationType.songRequestApproved ||
        NotificationType.songRequestRejected =>
          _NotificationCategory.songRequest,
        NotificationType.artistSuggestionProcessed =>
          _NotificationCategory.artistSuggestion,
        NotificationType.adminBroadcast => _NotificationCategory.adminBroadcast,
        NotificationType.adminPointGranted => _NotificationCategory.comment,
      };

  bool get isFestivalType => _category == _NotificationCategory.festival;

  bool get isCertType => _category == _NotificationCategory.cert;

  bool get isCommentType => _category == _NotificationCategory.comment;

  bool get isSongRequestType => _category == _NotificationCategory.songRequest;

  bool get isFestivalFilterType =>
      isFestivalType ||
      isSongRequestType ||
      _category == _NotificationCategory.artistSuggestion;

  bool get isArtistNavigationType =>
      isSongRequestType || _category == _NotificationCategory.artistSuggestion;

  bool get hasFestivalNavigation => isFestivalType || isCertType;
}

enum _NotificationCategory {
  festival,
  cert,
  comment,
  songRequest,
  artistSuggestion,
  adminBroadcast,
}
