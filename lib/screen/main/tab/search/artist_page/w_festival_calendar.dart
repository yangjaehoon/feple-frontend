import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_config.dart';
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
      final data =
          await sl<ArtistScheduleService>().fetchSchedule(widget.artistId);
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
          _buildAppBar(colors),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }

  Widget _buildAppBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.appBarColor,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.artistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.loadingIndicator),
      );
    }
    if (_hasError) {
      return Center(
        child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: _fetch),
      );
    }
    return SfCalendar(
      view: CalendarView.month,
      dataSource: _ScheduleDataSource(_buildAppointments()),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
      ),
      backgroundColor: colors.backgroundMain,
      todayHighlightColor: colors.activate,
      headerStyle: CalendarHeaderStyle(
        textStyle: TextStyle(
          color: colors.textTitle,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        backgroundColor: colors.backgroundMain,
      ),
      viewHeaderStyle: ViewHeaderStyle(
        dayTextStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
    );
  }

  List<Appointment> _buildAppointments() {
    final result = <Appointment>[];
    for (final s in _schedules) {
      if (s.startDate == null) continue;
      final start = DateTime.tryParse(s.startDate!);
      if (start == null) continue;
      final end = s.endDate != null
          ? (DateTime.tryParse(s.endDate!) ?? start).add(const Duration(days: 1))
          : start.add(const Duration(days: 1));
      final config = getEventTypeConfig(s.eventType);
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
