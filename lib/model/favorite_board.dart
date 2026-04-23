class FavoriteBoard {
  final String boardId;    // "artist_1" or "festival_3"
  final String type;       // "artist" | "festival"
  final int entityId;
  final String entityName;
  final String? imageUrl;

  const FavoriteBoard({
    required this.boardId,
    required this.type,
    required this.entityId,
    required this.entityName,
    this.imageUrl,
  });

  String get displayName => '$entityName 게시판';
}
