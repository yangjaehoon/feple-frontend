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
}
