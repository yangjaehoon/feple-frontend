import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

class CalendarHelper {
  const CalendarHelper._();

  static Future<void> addToDeviceCalendar(
    BuildContext context, {
    required String title,
    required String? startDate,
    String? endDate,
    String description = '',
    String location = '',
  }) async {
    final start = startDate != null ? DateTime.tryParse(startDate) : null;
    if (start == null) {
      if (context.mounted) context.showErrorSnackbar('add_to_calendar_no_date'.tr());
      return;
    }
    final parsedEnd = endDate != null ? DateTime.tryParse(endDate) : null;
    final end = (parsedEnd ?? start).add(const Duration(days: 1));

    await Add2Calendar.addEvent2Cal(
      Event(
        title: title,
        description: description,
        location: location,
        startDate: start,
        endDate: end,
        allDay: true,
      ),
    );
  }
}
