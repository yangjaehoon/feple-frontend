import 'json_reader.dart';
import 'timetable_entry.dart' show formatTimeRange;

class MyTimetableEntry {
  final String id;
  final String stageName;
  final String label;
  final String startTime;
  final String endTime;
  final int colorValue;

  MyTimetableEntry({
    required this.id,
    required this.stageName,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
  });

  String get timeRange => formatTimeRange(startTime, endTime);

  MyTimetableEntry copyWith({
    String? stageName,
    String? label,
    String? startTime,
    String? endTime,
    int? colorValue,
  }) =>
      MyTimetableEntry(
        id: id,
        stageName: stageName ?? this.stageName,
        label: label ?? this.label,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageName': stageName,
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
        'color': colorValue,
      };

  factory MyTimetableEntry.fromJson(Map<String, dynamic> j) => MyTimetableEntry(
        id: j.str('id'),
        stageName: j.str('stageName'),
        label: j.str('label'),
        startTime: j.str('startTime'),
        endTime: j.str('endTime'),
        colorValue: j.integer('color'),
      );
}
