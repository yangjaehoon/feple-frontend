import 'package:flutter/material.dart';

extension TimeOfDayFormat on TimeOfDay {
  String get toHHmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
