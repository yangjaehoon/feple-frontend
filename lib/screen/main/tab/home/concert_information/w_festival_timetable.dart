import 'package:fast_app_base/common/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class FestivalTimetable extends StatelessWidget {
  const FestivalTimetable({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SfCalendar(
          backgroundColor: colors.surface,
          headerStyle: CalendarHeaderStyle(
            textStyle: TextStyle(
              color: colors.textTitle,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: colors.surface,
          ),
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          monthViewSettings: MonthViewSettings(
            monthCellStyle: MonthCellStyle(
              textStyle: TextStyle(color: colors.textTitle, fontSize: 13),
              trailingDatesTextStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
              leadingDatesTextStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
            ),
          ),
          todayHighlightColor: colors.activate,
          selectionDecoration: BoxDecoration(
            border: Border.all(color: colors.activate, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}