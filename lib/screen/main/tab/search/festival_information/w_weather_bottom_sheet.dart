import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/common.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

class WeatherBottomSheet extends StatefulWidget {
  final int festivalId;

  const WeatherBottomSheet({super.key, required this.festivalId});

  @override
  State<WeatherBottomSheet> createState() => _WeatherBottomSheetState();
}

class _WeatherBottomSheetState extends State<WeatherBottomSheet> {
  late Future<WeatherModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<FestivalService>().fetchWeather(widget.festivalId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'weather_title'.tr(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<WeatherModel?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: colors.activate),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 48, color: colors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'weather_no_data'.tr(),
                        style: TextStyle(
                            fontSize: 14, color: colors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              final minT = data.minTemp.toStringAsFixed(0);
              final maxT = data.maxTemp.toStringAsFixed(0);

              return Column(
                children: [
                  Text(data.conditionIcon,
                      style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(
                    data.conditionKey.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoChip(
                        icon: Icons.thermostat_rounded,
                        label: 'weather_temp_range'.tr(args: [minT, maxT]),
                        color: const Color(0xFFFF7043),
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.water_drop_rounded,
                        label: 'weather_rain_prob'.tr(args: ['${data.rainProb}']),
                        color: _rainColor(data.rainProb),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _rainColor(int prob) {
    if (prob >= 70) return const Color(0xFF1565C0);
    if (prob >= 40) return const Color(0xFF42A5F5);
    return const Color(0xFF90CAF9);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: colors.text,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
