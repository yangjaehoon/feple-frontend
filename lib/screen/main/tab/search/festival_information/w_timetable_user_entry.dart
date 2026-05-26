import 'package:flutter/material.dart';

class UserEntry {
  final String id;
  String stageName;
  String label;
  String startTime;
  String endTime;
  Color color;

  UserEntry({
    required this.id,
    required this.stageName,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  String get timeRange => '$startTime – $endTime';

  UserEntry copyWith({
    String? stageName,
    String? label,
    String? startTime,
    String? endTime,
    Color? color,
  }) =>
      UserEntry(
        id: id,
        stageName: stageName ?? this.stageName,
        label: label ?? this.label,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        color: color ?? this.color,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageName': stageName,
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
        'color': color.toARGB32(),
      };

  factory UserEntry.fromJson(Map<String, dynamic> j) => UserEntry(
        id: j['id'] as String,
        stageName: j['stageName'] as String,
        label: j['label'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        color: Color(j['color'] as int),
      );
}
