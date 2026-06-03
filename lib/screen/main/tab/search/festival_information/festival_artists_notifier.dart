import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/foundation.dart';

class FestivalArtistsNotifier extends ChangeNotifier {
  final int festivalId;
  final int? userId;
  final FestivalDetailService _festivalService;
  final ArtistFollowService _followService;

  List<FestivalArtistItem> artists = [];
  Set<int> followedIds = {};
  bool isLoading = true;
  bool hasError = false;

  // null = 전체, otherwise ISO date string
  String? selectedDate;

  FestivalArtistsNotifier({
    required this.festivalId,
    this.userId,
    required FestivalDetailService festivalService,
    required ArtistFollowService followService,
  })  : _festivalService = festivalService,
        _followService = followService;

  bool isFollowed(int artistId) => followedIds.contains(artistId);

  /// 날짜 탭에 표시할 정렬된 날짜 목록 (아티스트들의 performanceDates 합집합)
  List<String> get allDates {
    final seen = <String>{};
    final dates = <String>[];
    for (final a in artists) {
      for (final d in a.performanceDates) {
        if (seen.add(d)) dates.add(d);
      }
    }
    dates.sort();
    return dates;
  }

  bool get hasDateFilter => allDates.length > 1;

  List<FestivalArtistItem> get displayedArtists {
    if (selectedDate == null) return artists;
    return artists.where((a) => a.performanceDates.contains(selectedDate)).toList();
  }

  void selectDate(String? date) {
    if (selectedDate == date) return;
    selectedDate = date;
    notifyListeners();
  }

  Future<void> retry() async {
    hasError = false;
    isLoading = true;
    notifyListeners();
    await fetch();
  }

  Future<void> fetch() async {
    try {
      final fetched = await _festivalService.fetchFestivalArtists(festivalId);

      Set<int> followed = {};
      if (userId != null) {
        followed = await _followService.getFollowingIds(userId!);
      }

      fetched.sort((a, b) {
        final aRank = followed.contains(a.artistId) ? 0 : 1;
        final bRank = followed.contains(b.artistId) ? 0 : 1;
        return aRank.compareTo(bRank);
      });

      artists = fetched;
      followedIds = followed;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hasError = true;
      notifyListeners();
      debugPrint('festival artists fetch error: $e');
    }
  }
}
