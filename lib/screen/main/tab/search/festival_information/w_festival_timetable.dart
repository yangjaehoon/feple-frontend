import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/util/app_route.dart';
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
  bool _isVerticalScrollLocked = false, _isHorizontalScrollLocked = false;

  List<TimetableEntry> _entries = [];
  Set<String> _followedNames = {};
  bool _loading = true;
  String? _error;

  List<String> _dates = [];
  String? _selectedDate;

  TimetableRange get _range => computeTimetableRange(_entries, _selectedDate);

  @override
  void initState() {
    super.initState();
    _vContent.addListener(_syncVerticalScroll);
    _hContent.addListener(_syncHorizontalScroll);
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
        _dates.add(d.toYMD);
      }
      _selectedDate = _dates.isNotEmpty ? _dates.first : null;
    } catch (e) {
      debugPrint('[Timetable] date parse failed: $e');
    }
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
      } catch (e) {
        debugPrint('[Timetable] fetchFollowedArtists failed: $e');
      }

      if (mounted) {
        setState(() {
          _entries = list;
          _followedNames = followed;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('timetable fetch error: $e');
      if (mounted) setState(() { _error = 'err_fetch_data'.tr(); _loading = false; });
    }
  }

  void _syncVerticalScroll() {
    if (_isVerticalScrollLocked) return;
    _isVerticalScrollLocked = true;
    if (_vTime.hasClients) _vTime.jumpTo(_vContent.offset);
    _isVerticalScrollLocked = false;
  }

  void _syncHorizontalScroll() {
    if (_isHorizontalScrollLocked) return;
    _isHorizontalScrollLocked = true;
    if (_hHeader.hasClients) _hHeader.jumpTo(_hContent.offset);
    _isHorizontalScrollLocked = false;
  }

  @override
  void dispose() {
    _vContent.removeListener(_syncVerticalScroll);
    _hContent.removeListener(_syncHorizontalScroll);
    _vContent.dispose();
    _vTime.dispose();
    _hContent.dispose();
    _hHeader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SurfaceCard(
      margin: const EdgeInsets.all(AppDimens.paddingHorizontal),
      shadowAlpha: 0.1,
      clipContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  if (!_loading && _error == null && _range.filtered.isNotEmpty)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        SlideRoute(
                          builder: (_) => TimetableFullscreenPage(
                            festivalId: widget.festivalId,
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

            if (_dates.isNotEmpty)
              DateTabBar(
                dates: _dates,
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() {
                  _selectedDate = date;
                }),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelBuilder: (d) => d,
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
            else if (_range.filtered.isEmpty)
              EmptyState(icon: Icons.schedule_rounded, title: 'no_timetable'.tr())
            else
              LayoutBuilder(
                builder: (_, constraints) => TimetableGrid(
                  stages: _range.stages,
                  filtered: _range.filtered,
                  startHour: _range.startHour,
                  endHour: _range.endHour,
                  followedNames: _followedNames,
                  availableW: constraints.maxWidth,
                  scrollControllers: TimetableScrollControllers(
                    hHeader: _hHeader,
                    hContent: _hContent,
                    vContent: _vContent,
                    vTime: _vTime,
                  ),
                ),
              ),
          ],
      ),
    );
  }
}
