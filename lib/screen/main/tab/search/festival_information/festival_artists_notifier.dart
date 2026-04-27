import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/foundation.dart';

class FestivalArtistsNotifier extends ChangeNotifier {
  final int festivalId;
  final int? userId;
  final FestivalService _festivalService;
  final ArtistFollowService _followService;

  List<FestivalArtistItem> artists = [];
  Set<int> followedIds = {};
  bool isLoading = true;
  void Function(String)? onError;

  FestivalArtistsNotifier({
    required this.festivalId,
    this.userId,
    required FestivalService festivalService,
    required ArtistFollowService followService,
  })  : _festivalService = festivalService,
        _followService = followService;

  Future<void> fetch() async {
    try {
      final fetched = await _festivalService.fetchFestivalArtists(festivalId);

      Set<int> followed = {};
      if (userId != null) {
        followed = await _followService.getFollowingIds(userId!);
      }

      // 팔로우한 아티스트를 앞으로 정렬
      fetched.sort((a, b) {
        final aF = followed.contains(a.artistId) ? 0 : 1;
        final bF = followed.contains(b.artistId) ? 0 : 1;
        return aF.compareTo(bF);
      });

      artists = fetched;
      followedIds = followed;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      onError?.call(e.toString());
    }
  }
}
