import 'package:feple/model/timetable_entry.dart';

abstract class FestivalTimetableFetcher {
  Future<List<TimetableEntry>> fetchTimetable(int festivalId);
}
