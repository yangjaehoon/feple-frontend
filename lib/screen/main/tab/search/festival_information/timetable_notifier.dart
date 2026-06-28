import 'package:easy_localization/easy_localization.dart';
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
  String? error;

  List<String> dates = [];
  String? selectedDate;

  TimetableRange? _cachedRange;
  TimetableRange get range => _cachedRange ??= computeTimetableRange(entries, selectedDate);

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
  })  : _festivalService = festivalService,
        _followService = followService {
    _buildDates(startDate, endDate);
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
      debugPrint('[Timetable] date parse failed: $e');
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
      _cachedRange = computeTimetableRange(entries, selectedDate);
      safeNotify();
    } catch (e) {
      debugPrint('timetable fetch error: $e');
      error = 'err_fetch_data'.tr();
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
}
