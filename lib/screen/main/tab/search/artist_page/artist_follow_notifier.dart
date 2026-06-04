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
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  ArtistFollowNotifier({required this.artistId, required int initialFollowerCount}) {
    followCount = initialFollowerCount;
  }

  Future<void> init() async {
    try {
      final status = await _followService.getFollowStatus(artistId);
      isFollowed = status.followed;
      followCount = status.followerCount;
      _safeNotify();
    } catch (e) {
      debugPrint('[FollowNotifier] init failed: $e');
    }
  }

  Future<void> toggle() async {
    if (isLoading) return;
    isLoading = true;
    final prevFollowed = isFollowed;
    final prevCount = followCount;
    isFollowed = !isFollowed;
    followCount += isFollowed ? 1 : -1;
    _safeNotify();
    HapticFeedback.mediumImpact();
    try {
      if (prevFollowed) {
        await _followService.unfollow(artistId);
      } else {
        await _followService.follow(artistId);
      }
    } catch (e) {
      isFollowed = prevFollowed;
      followCount = prevCount;
      debugPrint('[FollowNotifier] toggle error: $e');
      rethrow;
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }
}
