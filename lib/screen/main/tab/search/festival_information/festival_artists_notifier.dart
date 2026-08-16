import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/util/dio_error_helper.dart';
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

  // refresh() 실패 시 설정 — UI가 snackbar로 표시 후 clearRefreshError() 호출 (일회성)
  String? refreshError;
  void clearRefreshError() => refreshError = null;

  // null = 전체, otherwise ISO date string
  String? selectedDate;

  FestivalArtistsNotifier({
    required this.festivalId,
    this.userId,
    required FestivalArtistsFetcher festivalService,
    required ArtistFollowService followService,
  }) : _festivalService = festivalService,
       _followService = followService {
    AppEvents.artistFollowChanged.addListener(_onFollowChanged);
  }

  @override
  void dispose() {
    AppEvents.artistFollowChanged.removeListener(_onFollowChanged);
    super.dispose();
  }

  // 다른 화면(아티스트 상세 등)에서 팔로우 상태가 바뀌면 이 화면에 캐시된
  // followedIds도 갱신 — 라인업 전체를 다시 불러올 필요 없이 팔로우 목록만 재조회.
  void _onFollowChanged() {
    if (userId == null) return;
    _refreshFollowedIds();
  }

  Future<void> _refreshFollowedIds() async {
    try {
      followedIds = await _followService.fetchFollowingIds(userId!);
      safeNotify();
    } catch (e) {
      debugPrint('[FestivalArtists] follow refresh error: $e');
    }
  }

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

  /// Pull-to-refresh용 — 실패해도 기존 목록은 유지하되(크래시 방지), 실패 사실은
  /// refreshError로 알려 UI가 snackbar를 띄울 수 있게 한다.
  Future<void> refresh() async {
    try {
      await _fetchAndApply();
      hasError = false;
      safeNotify();
    } catch (e) {
      debugPrint('festival artists refresh error: $e');
      refreshError = networkAwareErrorKey(e, 'err_fetch_data').tr();
      safeNotify();
    }
  }

  Future<void> _fetchAndApply() async {
    final (fetched, followed) = await (
      _festivalService.fetchFestivalArtists(festivalId),
      userId != null
          ? _followService.fetchFollowingIds(userId!)
          : Future<Set<int>>.value({}),
    ).wait;

    // List.sort는 stable 정렬을 보장하지 않아 같은 순위(팔로우 여부) 그룹 내
    // 원래 서버 순서가 fetch마다 흔들릴 수 있다 — dart:ui(flutter/foundation)의
    // stable 정렬 mergeSort 사용
    mergeSort(fetched, compare: (a, b) {
      final aRank = followed.contains(a.artistId) ? 0 : 1;
      final bRank = followed.contains(b.artistId) ? 0 : 1;
      return aRank.compareTo(bRank);
    });

    artists = fetched;
    followedIds = followed;
    allDates = _computeAllDates(fetched);
    // 새로 불러온 결과에 더 이상 존재하지 않는 날짜가 선택돼 있으면, 목록이
    // 아무 이유 없이 텅 비어 보이는 걸 막기 위해 "전체" 상태로 되돌린다.
    if (selectedDate != null && !allDates.contains(selectedDate)) {
      selectedDate = null;
    }
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
