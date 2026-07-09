import 'package:feple/app.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/widgets.dart';

class FcmNavigationHandler {
  Future<void> navigate(Map<String, dynamic> data) async {
    final nav = App.navigatorKey.currentState;
    if (nav == null) return;

    final type = NotificationType.fromValue(data['type'] as String?);
    // 백엔드가 festivalId 키에 타입에 따라 festivalId 뿐 아니라 postId/artistId도
    // 함께 실어 보냄 (FcmPushService.sendMulticast의 linkId) — 범용 참조 ID로 취급
    final linkIdStr = data['festivalId'] as String?;
    final linkId = (linkIdStr?.isNotEmpty == true) ? int.tryParse(linkIdStr!) : null;

    if (linkId != null) {
      if (type?.hasFestivalNavigation ?? false) {
        if (await _pushFestival(nav, linkId)) return;
      } else if (type?.isCommentType ?? false) {
        if (await _pushPost(nav, linkId)) return;
      } else if (type?.isArtistNavigationType ?? false) {
        if (await _pushArtist(nav, linkId)) return;
      }
    }
    nav.push(SlideRoute(builder: (_) => const NotificationScreen()));
  }

  Future<bool> _pushFestival(NavigatorState nav, int festivalId) async {
    try {
      final festival = await sl<FestivalService>().fetchById(festivalId);
      nav.push(SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)));
      return true;
    } catch (e) {
      debugPrint('[FCM Nav] 페스티벌 이동 실패: $e');
      return false;
    }
  }

  Future<bool> _pushPost(NavigatorState nav, int postId) async {
    try {
      final post = await sl<PostService>().fetchPost(postId);
      nav.push(SlideRoute(
        builder: (_) => PostDetailCard.fromPost(boardName: post.boardDisplayName, post: post),
      ));
      return true;
    } catch (e) {
      debugPrint('[FCM Nav] 게시글 이동 실패: $e');
      return false;
    }
  }

  Future<bool> _pushArtist(NavigatorState nav, int artistId) async {
    try {
      final artist = await sl<ArtistService>().fetchArtistById(artistId);
      nav.push(SlideRoute(
        builder: (_) => ArtistScreen(
          artistId: artist.id,
          artistName: artist.name,
          artistNameEn: artist.nameEn,
          followerCount: artist.followerCount,
          profileImageUrl: artist.profileImageUrl,
        ),
      ));
      return true;
    } catch (e) {
      debugPrint('[FCM Nav] 아티스트 이동 실패: $e');
      return false;
    }
  }
}
