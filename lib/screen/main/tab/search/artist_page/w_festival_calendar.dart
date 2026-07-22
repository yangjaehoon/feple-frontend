import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

class FestivalCalendar extends StatefulWidget {
  const FestivalCalendar({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  final int artistId;
  final String artistName;

  @override
  State<FestivalCalendar> createState() => _FestivalCalendarState();
}

class _FestivalCalendarState extends State<FestivalCalendar> {
  final _scheduleService = sl<ArtistScheduleService>();
  final _festivalService = sl<FestivalService>();
  List<ArtistScheduleModel> _schedules = [];
  bool _isLoading = true;
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _scheduleService.fetchSchedule(widget.artistId);
      if (!mounted) return;
      setState(() {
        _schedules = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[FestivalCalendar] fetch error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.artistName),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_hasError) {
      return Center(child: ErrorState.network(_error!, onRetry: _fetch));
    }
    if (_schedules.isEmpty) {
      return Center(
        child: Text(
          'no_schedule'.tr(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: AppDimens.fontSizeMd,
          ),
        ),
      );
    }

    final upcoming = _schedules.where((s) => !s.isPast).toList();
    final past = _schedules.where((s) => s.isPast).toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _future = _fetch();
        });
        try {
          await _future;
        } catch (_) {}
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (upcoming.isNotEmpty) ...[
            _buildSectionHeader('schedule_upcoming'.tr(), colors),
            ...upcoming.map((s) => _buildScheduleItem(s, colors)),
          ],
          if (past.isNotEmpty) ...[
            _buildSectionHeader('schedule_past'.tr(), colors),
            ...past.map((s) => _buildScheduleItem(s, colors)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ArtistScheduleModel s, AbstractThemeColors colors) {
    final config = s.eventType.config(colors);
    final dateText = _formatDateRange(s.startDate, s.endDate);
    final isPast = s.isPast;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        side: BorderSide(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        onTap: () => _navigateToFestival(s.festivalId),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: isPast ? 0.15 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  config.icon,
                  size: 18,
                  color: isPast ? colors.textSecondary : config.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeMd,
                        fontWeight: FontWeight.w600,
                        color: isPast ? colors.textSecondary : colors.textTitle,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateText != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: AppDimens.fontSizeXs,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (s.location != null && s.location!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              s.location!,
                              style: TextStyle(
                                fontSize: AppDimens.fontSizeXs,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildCalendarButton(s, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarButton(
    ArtistScheduleModel s,
    AbstractThemeColors colors,
  ) {
    return Tooltip(
      message: 'add_to_calendar'.tr(),
      child: IconButton(
        icon: const Icon(Icons.calendar_today_rounded),
        iconSize: 20,
        color: colors.activate,
        style: IconButton.styleFrom(
          backgroundColor: colors.activate.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
        ),
        onPressed: () => _saveToCalendar(s),
      ),
    );
  }

  Future<void> _saveToCalendar(ArtistScheduleModel s) async {
    final startDate = s.startDate != null
        ? DateTime.tryParse(s.startDate!)
        : null;
    if (startDate == null) {
      if (mounted) context.showErrorSnackbar('add_to_calendar_no_date'.tr());
      return;
    }
    final endDate = s.endDate != null
        ? (DateTime.tryParse(s.endDate!) ?? startDate).add(
            const Duration(days: 1),
          )
        : startDate.add(const Duration(days: 1));

    final event = Event(
      title: s.title,
      description: s.description ?? '',
      location: s.location ?? '',
      startDate: startDate,
      endDate: endDate,
      allDay: true,
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _navigateToFestival(int festivalId) async {
    try {
      final festival = await _festivalService.fetchById(festivalId);
      if (!mounted) return;
      Navigator.push(
        context,
        SlideRoute(
          builder: (_) => FestivalInformationFragment(poster: festival),
        ),
      );
    } catch (e) {
      debugPrint('[FestivalCalendar] festival fetch error: $e');
      if (mounted) {
        context.showErrorSnackbar(
          networkAwareErrorKey(e, 'err_fetch_data').tr(),
        );
      }
    }
  }

  String? _formatDateRange(String? startDate, String? endDate) {
    final start = startDate != null ? DateTime.tryParse(startDate) : null;
    if (start == null) return null;
    final startStr = start.toDisplayDate;
    if (endDate == null) return startStr;
    final end = DateTime.tryParse(endDate);
    if (end == null || end == start) return startStr;
    return '$startStr ~ ${end.toDisplayDate}';
  }

  // RefreshIndicator onRefresh 패턴
  Future<void> _future = Future.value();
}
