import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_board.dart';
import 'package:flutter/material.dart';

/// FavoriteBoard 탭 시 타입별 게시판 화면으로 이동 — 즐겨찾는 게시판 목록의
/// 여러 화면(전체보기/홈 섹션)에서 동일 라우팅 로직을 반복하지 않도록 공용화.
extension FavoriteBoardNavigation on FavoriteBoard {
  void navigate(BuildContext context) {
    final displayEntityName = entityDisplayName(context.isEnglish);
    final route = switch (type) {
      FavoriteBoardType.artist => SlideRoute(
          builder: (_) => ArtistPostListScreen(
            artistId: entityId,
            artistName: displayEntityName,
          ),
        ),
      FavoriteBoardType.festival => SlideRoute(
          builder: (_) => FestivalBoardScreen(
            festivalId: entityId,
            festivalName: displayEntityName,
          ),
        ),
    };
    Navigator.push(context, route);
  }
}
