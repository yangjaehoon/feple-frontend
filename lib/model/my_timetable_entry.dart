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

  String get timeRange => '$startTime – $endTime';

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
        id: j['id'] as String,
        stageName: j['stageName'] as String,
        label: j['label'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        colorValue: j['color'] as int,
      );
}
