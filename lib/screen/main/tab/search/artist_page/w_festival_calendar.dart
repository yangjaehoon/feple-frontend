import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
  List<ArtistScheduleModel> _schedules = [];
  bool _isLoading = true;
  bool _hasError = false;

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
      return Center(
        child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: _fetch),
      );
    }
    return SfCalendar(
      view: CalendarView.month,
      dataSource: _ScheduleDataSource(_buildAppointments(colors)),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
      ),
      backgroundColor: colors.backgroundMain,
      todayHighlightColor: colors.activate,
      headerStyle: CalendarHeaderStyle(
        textStyle: TextStyle(
          color: colors.textTitle,
          fontWeight: FontWeight.w700,
          fontSize: AppDimens.fontSizeXxl,
        ),
        backgroundColor: colors.backgroundMain,
      ),
      viewHeaderStyle: ViewHeaderStyle(
        dayTextStyle: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXs),
      ),
    );
  }

  List<Appointment> _buildAppointments(AbstractThemeColors colors) {
    final result = <Appointment>[];
    for (final s in _schedules) {
      if (s.startDate == null) continue;
      final start = DateTime.tryParse(s.startDate!);
      if (start == null) continue;
      final end = s.endDate != null
          ? (DateTime.tryParse(s.endDate!) ?? start).add(const Duration(days: 1))
          : start.add(const Duration(days: 1));
      final config = s.eventType.config(colors);
      result.add(Appointment(
        startTime: start,
        endTime: end,
        subject: s.title,
        color: config.color,
        isAllDay: true,
      ));
    }
    return result;
  }
}

class _ScheduleDataSource extends CalendarDataSource {
  _ScheduleDataSource(List<Appointment> source) {
    appointments = source;
  }
}
