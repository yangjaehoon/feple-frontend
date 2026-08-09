import 'localized_text.dart';

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
      pickLocalized(isEnglish, entityName, entityNameEn);
}

extension FavoriteBoardListExtension on List<FavoriteBoard> {
  /// 저장된 순서(id 리스트) 기준으로 실제 FavoriteBoard 객체를 정렬해 반환.
  /// 존재하지 않는 id(삭제된 보드 등)는 조용히 걸러진다.
  List<FavoriteBoard> resolveOrdered(List<String> orderedIds) {
    final map = {for (final b in this) b.boardId: b};
    return orderedIds.map((id) => map[id]).whereType<FavoriteBoard>().toList();
  }
}
