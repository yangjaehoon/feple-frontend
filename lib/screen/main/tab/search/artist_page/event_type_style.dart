import 'package:feple/common/common.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:flutter/material.dart';

class EventTypeConfig {
  final IconData icon;
  final Color color;
  const EventTypeConfig({required this.icon, required this.color});
}

extension EventTypeStyle on EventType {
  EventTypeConfig config(AbstractThemeColors colors) {
    switch (this) {
      case EventType.fanMeeting:
        return EventTypeConfig(icon: Icons.favorite_rounded, color: AppColors.kawaiiPink);
      case EventType.tvShow:
        return EventTypeConfig(icon: Icons.tv_rounded, color: AppColors.kawaiiPurple);
      case EventType.festival:
        return EventTypeConfig(icon: Icons.music_note_rounded, color: colors.activate);
    }
  }
}
