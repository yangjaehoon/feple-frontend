import 'dart:async';

import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/app_review_service.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ArtistFollowNotifier extends SafeChangeNotifier {
  final int artistId;
  final _followService = sl<ArtistFollowService>();

  bool isFollowed = false;
  int followCount = 0;
  bool isLoading = false;
  bool initFailed = false;

  String get followStatusKey => isFollowed ? 'follow_done' : 'follow_cancel';

  ArtistFollowNotifier({required this.artistId, required int initialFollowerCount}) {
    followCount = initialFollowerCount;
  }

  Future<void> init() async {
    try {
      final status = await _followService.getFollowStatus(artistId);
      // 토글이 진행 중이면 낙관적으로 반영해둔 상태를 덮어쓰지 않는다 — 늦게
      // 도착한 조회 응답이 방금 누른 팔로우를 되돌려놓고, toggle()의 finally는
      // isLoading만 건드리므로 잘못된 상태가 다음 새로고침까지 남는다.
      if (!isLoading) {
        isFollowed = status.followed;
        followCount = status.followerCount;
      }
      // 되돌리지 않으면 한 번 실패한 뒤로는 당겨서 새로고침이 성공해도
      // 팔로우 버튼이 비활성(dimmed)인 채로 남는다
      initFailed = false;
      safeNotify();
    } catch (e) {
      debugPrint('[FollowNotifier] init failed: $e');
      initFailed = true;
      safeNotify();
    }
  }

  Future<void> toggle() async {
    if (isLoading) return;
    isLoading = true;
    final prevFollowed = isFollowed;
    final prevCount = followCount;
    isFollowed = !isFollowed;
    followCount += isFollowed ? 1 : -1;
    safeNotify();
    unawaited(HapticFeedback.mediumImpact());
    try {
      if (prevFollowed) {
        await _followService.unfollow(artistId);
      } else {
        await _followService.follow(artistId);
        unawaited(AppReviewService.recordArtistFollowed());
      }
    } catch (e) {
      isFollowed = prevFollowed;
      followCount = prevCount;
      debugPrint('[FollowNotifier] toggle error: $e');
      rethrow;
    } finally {
      isLoading = false;
      safeNotify();
    }
  }
}
