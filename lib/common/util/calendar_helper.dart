import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:feple/common/common.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:flutter/material.dart';

class CalendarHelper {
  const CalendarHelper._();

  static Future<void> addToDeviceCalendar(
    BuildContext context,
    ArtistScheduleModel item,
  ) async {
    final startDate = item.startDate != null
        ? DateTime.tryParse(item.startDate!)
        : null;
    if (startDate == null) {
      context.showErrorSnackbar('add_to_calendar_no_date'.tr());
      return;
    }
    final endDate = item.endDate != null
        ? (DateTime.tryParse(item.endDate!) ?? startDate).add(
            const Duration(days: 1),
          )
        : startDate.add(const Duration(days: 1));

    await Add2Calendar.addEvent2Cal(
      Event(
        title: item.title,
        description: item.description ?? '',
        location: item.location ?? '',
        startDate: startDate,
        endDate: endDate,
        allDay: true,
      ),
    );
  }
}
