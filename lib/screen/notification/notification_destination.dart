import 'package:feple/injection.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/widgets.dart';

/// (알림 타입 + 참조 ID) → 이동할 화면. 라우팅 규칙을 한 곳에 모아, FCM 탭 처리와
/// 알림 목록 화면이 각자 같은 분기표를 들고 있던 중복을 없앤다.
/// 이동 대상이 없는 타입이거나 [referenceId]가 없으면 null.
Future<Widget?> resolveNotificationDestination(
  NotificationType? type,
  int? referenceId,
) async {
  if (type == null || referenceId == null) return null;

  if (type.hasFestivalNavigation) {
    final festival = await sl<FestivalService>().fetchById(referenceId);
    return FestivalInformationFragment(poster: festival);
  }
  if (type.isCommentType) {
    final post = await sl<PostService>().fetchPost(referenceId);
    return PostDetailCard.fromPost(
      boardName: post.boardDisplayName,
      post: post,
    );
  }
  if (type.isArtistNavigationType) {
    final artist = await sl<ArtistService>().fetchArtistById(referenceId);
    return ArtistScreen.fromArtist(artist);
  }
  return null;
}
