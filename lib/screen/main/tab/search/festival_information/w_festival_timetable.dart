import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_timetable_fullscreen.dart';
import 'package:feple/screen/main/tab/search/festival_information/timetable_notifier.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_grid.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_skeleton.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
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

  late final TimetableNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _vContent.addListener(_syncVerticalScroll);
    _hContent.addListener(_syncHorizontalScroll);
    final userId = context.read<UserProvider>().currentUserId;
    _notifier = TimetableNotifier(
      festivalId: widget.festivalId,
      userId: userId,
      startDate: widget.startDate,
      endDate: widget.endDate,
      festivalService: sl<FestivalDetailService>(),
      followService: sl<ArtistFollowService>(),
    );
    _notifier.fetch();
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
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SurfaceCard(
      margin: const EdgeInsets.all(AppDimens.paddingHorizontal),
      shadowAlpha: 0.1,
      clipContent: true,
      child: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            if (_notifier.dates.isNotEmpty)
              DateTabBar(
                dates: _notifier.dates,
                selectedDate: _notifier.selectedDate,
                onDateSelected: _notifier.selectDate,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelBuilder: (d) => d,
              ),
            _buildBody(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 15, color: colors.activate),
          const SizedBox(width: 8),
          Text('timetable'.tr(),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: colors.textTitle)),
          const Spacer(),
          if (!_notifier.isLoading && _notifier.error == null && _notifier.hasEntries)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                SlideRoute(
                  builder: (_) => TimetableFullscreenPage(
                    festivalId: widget.festivalId,
                    entries: _notifier.entries,
                    followedNames: _notifier.followedNames,
                    dates: _notifier.dates,
                    initialDate: _notifier.selectedDate,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.activate.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                ),
                child: Icon(Icons.open_in_full_rounded, size: 16, color: colors.activate),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    if (_notifier.isLoading) return const TimetableSkeleton();
    if (_notifier.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ErrorState(
          message: 'err_fetch_data'.tr(),
          onRetry: _notifier.retry,
        ),
      );
    }
    if (!_notifier.hasEntries) {
      return EmptyState(icon: Icons.schedule_rounded, title: 'no_timetable'.tr());
    }
    return LayoutBuilder(
      builder: (_, constraints) => TimetableGrid(
        stages: _notifier.stages,
        filtered: _notifier.filteredEntries,
        startHour: _notifier.startHour,
        endHour: _notifier.endHour,
        followedNames: _notifier.followedNames,
        availableW: constraints.maxWidth,
        scrollControllers: TimetableScrollControllers(
          hHeader: _hHeader,
          hContent: _hContent,
          vContent: _vContent,
          vTime: _vTime,
        ),
      ),
    );
  }
}
