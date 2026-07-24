class PostChangedEvent {
  /// null = 전체 갱신 신호, non-null = 특정 게시글 변경
  final int? postId;

  PostChangedEvent({this.postId});
  PostChangedEvent.refreshAll() : postId = null;
  PostChangedEvent.specific(int id) : postId = id;
}
