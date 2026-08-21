import 'package:feple/common/app_events.dart';
import 'package:feple/common/dart/extension/datetime_extension.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_timetable_fetcher.dart';
import 'package:flutter/foundation.dart';

class TimetableNotifier extends SafeChangeNotifier {
  final int festivalId;
  final int? userId;
  final FestivalTimetableFetcher _festivalService;
  final ArtistFollowService _followService;

  List<TimetableEntry> entries = [];
  Set<String> followedNames = {};
  bool isLoading = true;
  Object? error;

  List<String> dates = [];
  String? selectedDate;

  TimetableRange? _cachedRange;
  TimetableRange get range =>
      _cachedRange ??= computeTimetableRange(entries, selectedDate);

  bool get hasEntries => range.filtered.isNotEmpty;
  List<String> get stages => range.stages;
  List<TimetableEntry> get filteredEntries => range.filtered;
  int get startHour => range.startHour;
  int get endHour => range.endHour;

  TimetableNotifier({
    required this.festivalId,
    this.userId,
    required String startDate,
    required String endDate,
    required FestivalTimetableFetcher festivalService,
    required ArtistFollowService followService,
  }) : _festivalService = festivalService,
       _followService = followService {
    _buildDates(startDate, endDate);
    AppEvents.artistFollowChanged.addListener(_onFollowChanged);
  }

  @override
  void dispose() {
    AppEvents.artistFollowChanged.removeListener(_onFollowChanged);
    super.dispose();
  }

  // 다른 화면에서 팔로우 상태가 바뀌면 타임테이블의 팔로우 하이라이트도 갱신 —
  // 전체 타임테이블을 다시 불러올 필요 없이 팔로우 이름 목록만 재조회.
  void _onFollowChanged() {
    if (userId == null) return;
    _refreshFollowedNames();
  }

  Future<void> _refreshFollowedNames() async {
    try {
      followedNames = await _safeFollowedNames();
      _cachedRange = computeTimetableRange(entries, selectedDate);
      safeNotify();
    } catch (e) {
      debugPrint('[Timetable] follow refresh error: $e');
    }
  }

  void _buildDates(String startDate, String endDate) {
    if (startDate.isEmpty) return;
    try {
      final start = DateTime.parse(startDate);
      final end = endDate.isNotEmpty ? DateTime.parse(endDate) : start;
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        dates.add(d.toYMD);
      }
      if (dates.isNotEmpty) {
        final today = DateTime.now().toYMD;
        selectedDate = dates.contains(today) ? today : dates.first;
      }
    } catch (e) {
      // dates가 비어 hasEntries가 false가 되면 화면은 "일정 없음"으로 보이는데,
      // 실제로는 날짜 파싱 오류다 — error를 남겨 fetch() 실패와 동일하게 구분되게 한다
      debugPrint('[Timetable] date parse failed: $e');
      error = e;
    }
  }

  Future<void> fetch() async {
    try {
      final (list, followed) = await (
        _festivalService.fetchTimetable(festivalId),
        _safeFollowedNames(),
      ).wait;

      entries = list;
      followedNames = followed;
      isLoading = false;
      error = null; // _buildDates 실패로 남아있었을 수 있는 이전 에러 상태 정리
      _cachedRange = computeTimetableRange(entries, selectedDate);
      safeNotify();
    } catch (e) {
      debugPrint('timetable fetch error: $e');
      error = e;
      isLoading = false;
      safeNotify();
    }
  }

  Future<Set<String>> _safeFollowedNames() async {
    if (userId == null) return {};
    try {
      return await _followService.fetchFollowedArtistNames(userId!);
    } catch (e) {
      debugPrint('[Timetable] fetchFollowedArtists failed: $e');
      return {};
    }
  }

  void selectDate(String? date) {
    selectedDate = date;
    _cachedRange = computeTimetableRange(entries, selectedDate);
    safeNotify();
  }

  Future<void> retry() async {
    error = null;
    isLoading = true;
    safeNotify();
    await fetch();
  }

  // FestivalTimetable의 startDate/endDate가 뒤늦게(상위 화면의 상세 재조회로)
  // 갱신되면 날짜 탭도 다시 계산해야 한다 — entries 자체는 festivalId만으로
  // 조회되므로 재조회는 불필요, 날짜 목록만 다시 만든다.
  void updateDateRange(String startDate, String endDate) {
    final previousSelected = selectedDate;
    dates = [];
    error = null;
    _buildDates(startDate, endDate);
    if (previousSelected != null && dates.contains(previousSelected)) {
      selectedDate = previousSelected;
    }
    _cachedRange = null;
    safeNotify();
  }
}
