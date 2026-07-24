enum NotificationFilter { all, cert, comment, festival }

extension NotificationFilterApi on NotificationFilter {
  String? get typeGroup => switch (this) {
    NotificationFilter.all      => null,
    NotificationFilter.cert     => 'cert',
    NotificationFilter.comment  => 'comment',
    NotificationFilter.festival => 'festival',
  };
}
