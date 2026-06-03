import 'package:flutter/material.dart';

Color rainProbColor(int prob) {
  if (prob >= 70) return const Color(0xFF1565C0);
  if (prob >= 40) return const Color(0xFF42A5F5);
  return const Color(0xFF90CAF9);
}
