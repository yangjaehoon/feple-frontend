import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_artists_fetcher.dart';
import 'package:flutter/foundation.dart';

class FestivalArtistsNotifier extends SafeChangeNotifier {
  final int festivalId;
  final int? userId;
  final FestivalArtistsFetcher _festivalService;
  final ArtistFollowService _followService;

  List<FestivalArtistItem> artists = [];
  Set<int> followedIds = {};
  bool isLoading = true;
  bool hasError = false;
  Object? error;
  List<String> allDates = [];

  // null = 전체, otherwise ISO date string
  String? selectedDate;

  FestivalArtistsNotifier({
    required this.festivalId,
    this.userId,
    required FestivalArtistsFetcher festivalService,
    required ArtistFollowService followService,
  }) : _festivalService = festivalService,
       _followService = followService;

  bool isFollowed(int artistId) => followedIds.contains(artistId);

  bool get hasDateFilter => allDates.length > 1;

  List<FestivalArtistItem> get displayedArtists {
    if (selectedDate == null) return artists;
    return artists
        .where((a) => a.performanceDates.contains(selectedDate))
        .toList();
  }

  void selectDate(String? date) {
    if (selectedDate == date) return;
    selectedDate = date;
    safeNotify();
  }

  Future<void> retry() async {
    hasError = false;
    isLoading = true;
    safeNotify();
    await fetch();
  }

  Future<void> fetch() async {
    try {
      await _fetchAndApply();
      isLoading = false;
      safeNotify();
    } catch (e) {
      isLoading = false;
      hasError = true;
      error = e;
      safeNotify();
      debugPrint('festival artists fetch error: $e');
    }
  }

  /// Pull-to-refresh용 — 실패해도 기존 목록을 유지하고 조용히 무시
  /// (다른 리스트 화면의 refresh()와 동일 패턴)
  Future<void> refresh() async {
    try {
      await _fetchAndApply();
      hasError = false;
      safeNotify();
    } catch (e) {
      debugPrint('festival artists refresh error: $e');
    }
  }

  Future<void> _fetchAndApply() async {
    final (fetched, followed) = await (
      _festivalService.fetchFestivalArtists(festivalId),
      userId != null
          ? _followService.fetchFollowingIds(userId!)
          : Future<Set<int>>.value({}),
    ).wait;

    // Dart List.sort는 stable 정렬 미보장 — 같은 순위(팔로우 여부) 그룹 내
    // 원래 서버 순서가 fetch마다 흔들릴 수 있음에 유의
    fetched.sort((a, b) {
      final aRank = followed.contains(a.artistId) ? 0 : 1;
      final bRank = followed.contains(b.artistId) ? 0 : 1;
      return aRank.compareTo(bRank);
    });

    artists = fetched;
    followedIds = followed;
    allDates = _computeAllDates(fetched);
  }

  static List<String> _computeAllDates(List<FestivalArtistItem> artists) {
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
}
