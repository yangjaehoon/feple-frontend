enum FavoriteBoardType { artist, festival }

class FavoriteBoard {
  final String boardId;    // "artist_1" or "festival_3"
  final FavoriteBoardType type;
  final int entityId;
  final String entityName;
  final String entityNameEn;
  final String? imageUrl;

  const FavoriteBoard({
    required this.boardId,
    required this.type,
    required this.entityId,
    required this.entityName,
    this.entityNameEn = '',
    this.imageUrl,
  });

  String entityDisplayName(bool isEnglish) =>
      isEnglish && entityNameEn.isNotEmpty ? entityNameEn : entityName;

  String displayName(bool isEnglish) {
    final name = entityDisplayName(isEnglish);
    return isEnglish ? '$name Board' : '$name 게시판';
  }
}
