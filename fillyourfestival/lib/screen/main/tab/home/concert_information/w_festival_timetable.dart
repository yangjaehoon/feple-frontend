import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class FestivalTimetable extends StatelessWidget {
  const FestivalTimetable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SfCalendar(),
    );
  }
}