import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:flutter/material.dart';

class EventTypeConfig {
  final IconData icon;
  final Color color;
  const EventTypeConfig({required this.icon, required this.color});
}

EventTypeConfig getEventTypeConfig(EventType eventType, AbstractThemeColors colors) {
  switch (eventType) {
    case EventType.fanMeeting:
      return EventTypeConfig(icon: Icons.favorite_rounded, color: AppColors.kawaiiPink);
    case EventType.tvShow:
      return EventTypeConfig(icon: Icons.tv_rounded, color: AppColors.kawaiiPurple);
    case EventType.festival:
      return EventTypeConfig(icon: Icons.music_note_rounded, color: colors.activate);
  }
}

class EventTypeIcon extends StatelessWidget {
  final EventTypeConfig config;
  const EventTypeIcon({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        border: Border.all(color: config.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(config.icon, color: config.color, size: 20),
    );
  }
}
