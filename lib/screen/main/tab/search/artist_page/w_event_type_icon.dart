import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:flutter/material.dart';

class EventTypeIcon extends StatelessWidget {
  final EventTypeConfig config;
  const EventTypeIcon({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 60,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        border: Border.all(color: config.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(config.icon, color: config.color, size: 20),
    );
  }
}
