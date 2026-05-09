import 'package:feple/injection.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ArtistFollowNotifier extends ChangeNotifier {
  final int artistId;
  final _followService = sl<ArtistFollowService>();

  bool isFollowed = false;
  int followCount = 0;
  bool isLoading = false;

  ArtistFollowNotifier({required this.artistId, required int initialFollowerCount}) {
    followCount = initialFollowerCount;
  }

  Future<void> init() async {
    try {
      final status = await _followService.getFollowStatus(artistId);
      isFollowed = status.followed;
      followCount = status.followerCount;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();
    HapticFeedback.mediumImpact();
    try {
      final res = isFollowed
          ? await _followService.unfollow(artistId)
          : await _followService.follow(artistId);
      isFollowed = res.followed;
      followCount = res.followerCount;
    } catch (_) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
