import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/datetime_extension.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/foundation.dart';

class TimetableNotifier extends ChangeNotifier {
  final int festivalId;
  final int? userId;
  final FestivalService _festivalService;
  final UserService _userService;

  List<TimetableEntry> entries = [];
  Set<String> followedNames = {};
  bool isLoading = true;
  String? error;

  List<String> dates = [];
  String? selectedDate;

  TimetableRange get range => computeTimetableRange(entries, selectedDate);

  TimetableNotifier({
    required this.festivalId,
    this.userId,
    required String startDate,
    required String endDate,
    required FestivalService festivalService,
    required UserService userService,
  })  : _festivalService = festivalService,
        _userService = userService {
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
          followed = await _userService.fetchFollowedArtistNames(userId!);
        }
      } catch (e) {
        debugPrint('[Timetable] fetchFollowedArtists failed: $e');
      }

      entries = list;
      followedNames = followed;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('timetable fetch error: $e');
      error = 'err_fetch_data'.tr();
      isLoading = false;
      notifyListeners();
    }
  }

  void selectDate(String? date) {
    selectedDate = date;
    notifyListeners();
  }

  Future<void> retry() async {
    error = null;
    isLoading = true;
    notifyListeners();
    await fetch();
  }
}
