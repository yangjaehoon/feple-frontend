import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_timetable_fullscreen.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_grid.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_skeleton.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FestivalTimetable extends StatefulWidget {
  final int festivalId;
  final String startDate;
  final String endDate;

  const FestivalTimetable({
    super.key,
    required this.festivalId,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<FestivalTimetable> createState() => _FestivalTimetableState();
}

class _FestivalTimetableState extends State<FestivalTimetable> {
  final _vContent = ScrollController();
  final _vTime = ScrollController();
  final _hContent = ScrollController();
  final _hHeader = ScrollController();
  bool _lockV = false, _lockH = false;

  List<TimetableEntry> _entries = [];
  Set<String> _followedNames = {};
  bool _loading = true;
  String? _error;

  List<String> _dates = [];
  String? _selectedDate;

  List<TimetableEntry> _cachedFiltered = [];
  List<String> _cachedStages = [];
  int _cachedStartHour = 12;
  int _cachedEndHour = 13;

  void _rebuildCache() {
    _cachedFiltered = _selectedDate == null
        ? []
        : _entries.where((e) => e.festivalDate == _selectedDate).toList();

    final seen = <String, int>{};
    for (final e in _cachedFiltered) {
      seen.putIfAbsent(e.stageName, () => e.stageOrder);
    }
    final sorted = seen.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    _cachedStages = sorted.map((e) => e.key).toList();

    int minH = 12;
    for (final e in _cachedFiltered) {
      final hour = int.tryParse(e.startTime.split(':')[0]);
      if (hour != null && hour < minH) minH = hour;
    }
    _cachedStartHour = minH;

    int maxH = minH + 1;
    for (final e in _cachedFiltered) {
      final parts = e.endTime.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
      if (hour == null || minute == null) continue;
      final endH = minute > 0 ? hour + 1 : hour;
      if (endH > maxH) maxH = endH;
    }
    _cachedEndHour = maxH;
  }

  @override
  void initState() {
    super.initState();
    _vContent.addListener(_onV);
    _hContent.addListener(_onH);
    _buildDates();
    _fetch();
  }

  void _buildDates() {
    if (widget.startDate.isEmpty) return;
    try {
      final start = DateTime.parse(widget.startDate);
      final end = widget.endDate.isNotEmpty ? DateTime.parse(widget.endDate) : start;
      _dates = [];
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        _dates.add(
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
      _selectedDate = _dates.isNotEmpty ? _dates.first : null;
    } catch (_) {}
  }

  Future<void> _fetch() async {
    final userId = context.read<UserProvider>().currentUserId;
    try {
      final list = await sl<FestivalService>().fetchTimetable(widget.festivalId);

      Set<String> followed = {};
      try {
        if (userId != null) {
          followed = await sl<UserService>().fetchFollowedArtistNames(userId);
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _entries = list;
          _followedNames = followed;
          _loading = false;
          _rebuildCache();
        });
      }
    } catch (e) {
      debugPrint('timetable fetch error: $e');
      if (mounted) setState(() { _error = 'err_fetch_data'.tr(); _loading = false; });
    }
  }

  void _onV() {
    if (_lockV) return;
    _lockV = true;
    if (_vTime.hasClients) _vTime.jumpTo(_vContent.offset);
    _lockV = false;
  }

  void _onH() {
    if (_lockH) return;
    _lockH = true;
    if (_hHeader.hasClients) _hHeader.jumpTo(_hContent.offset);
    _lockH = false;
  }

  @override
  void dispose() {
    _vContent.removeListener(_onV);
    _hContent.removeListener(_onH);
    _vContent.dispose();
    _vTime.dispose();
    _hContent.dispose();
    _hHeader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.cardShadow.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 15, color: colors.activate),
                  const SizedBox(width: 8),
                  Text('timetable'.tr(),
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: colors.textTitle)),
                  const Spacer(),
                  if (!_loading && _error == null && _cachedFiltered.isNotEmpty)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimetableFullscreenPage(
                            entries: _entries,
                            followedNames: _followedNames,
                            dates: _dates,
                            initialDate: _selectedDate,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.activate.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.open_in_full_rounded, size: 16, color: colors.activate),
                      ),
                    ),
                ],
              ),
            ),

            // 날짜 탭
            if (_dates.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _dates.map((date) {
                    final selected = date == _selectedDate;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedDate = date;
                        _rebuildCache();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8, bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? colors.activate : colors.backgroundMain,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? colors.activate : colors.listDivider,
                          ),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : colors.textTitle,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            if (_loading)
              const TimetableSkeleton()
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ErrorState(
                  message: 'err_fetch_data'.tr(args: ['']),
                  onRetry: () => setState(() {
                    _error = null;
                    _loading = true;
                    _fetch();
                  }),
                ),
              )
            else if (_cachedFiltered.isEmpty)
              EmptyState(icon: Icons.schedule_rounded, title: 'no_timetable'.tr())
            else
              LayoutBuilder(
                builder: (_, constraints) => TimetableGrid(
                  stages: _cachedStages,
                  filtered: _cachedFiltered,
                  startHour: _cachedStartHour,
                  endHour: _cachedEndHour,
                  followedNames: _followedNames,
                  availableW: constraints.maxWidth,
                  hHeader: _hHeader,
                  hContent: _hContent,
                  vContent: _vContent,
                  vTime: _vTime,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
