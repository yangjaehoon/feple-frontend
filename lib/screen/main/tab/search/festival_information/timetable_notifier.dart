import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/datetime_extension.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/foundation.dart';

class TimetableNotifier extends ChangeNotifier {
  final int festivalId;
  final int? userId;
  final FestivalDetailService _festivalService;
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

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) _safeNotify();
  }

  TimetableNotifier({
    required this.festivalId,
    this.userId,
    required String startDate,
    required String endDate,
    required FestivalDetailService festivalService,
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
      selectedDate = dates.isNotEmpty ? dates.first : null;
    } catch (e) {
      debugPrint('[Timetable] date parse failed: $e');
    }
  }

  Future<void> fetch() async {
    try {
      final list = await _festivalService.fetchTimetable(festivalId);

      Set<String> followed = {};
      try {
        if (userId != null) {
          followed = await _followService.fetchFollowedArtistNames(userId!);
        }
      } catch (e) {
        debugPrint('[Timetable] fetchFollowedArtists failed: $e');
      }

      entries = list;
      followedNames = followed;
      isLoading = false;
      _cachedRange = computeTimetableRange(entries, selectedDate);
      _safeNotify();
    } catch (e) {
      debugPrint('timetable fetch error: $e');
      error = 'err_fetch_data'.tr();
      isLoading = false;
      _safeNotify();
    }
  }

  void selectDate(String? date) {
    selectedDate = date;
    _cachedRange = computeTimetableRange(entries, selectedDate);
    _safeNotify();
  }

  Future<void> retry() async {
    error = null;
    isLoading = true;
    _safeNotify();
    await fetch();
  }
}
