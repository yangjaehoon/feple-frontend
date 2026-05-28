import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';

class FestivalWeather extends StatefulWidget {
  final int festivalId;

  const FestivalWeather({super.key, required this.festivalId});

  @override
  State<FestivalWeather> createState() => _FestivalWeatherState();
}

class _FestivalWeatherState extends State<FestivalWeather> {
  late Future<WeatherModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<FestivalDetailService>().fetchWeather(widget.festivalId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<WeatherModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(colors);
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return _WeatherCard(data: data);
      },
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: AppDimens.paddingVertical,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 13, width: 80),
                SizedBox(height: 6),
                SkeletonBox(height: 13, width: 120),
                SizedBox(height: 4),
                SkeletonBox(height: 11, width: 100),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const SkeletonBox(
            width: 28,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final WeatherModel data;

  const _WeatherCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final minT = data.minTemp.toStringAsFixed(0);
    final maxT = data.maxTemp.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: AppDimens.paddingVertical,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(data.conditionIcon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'weather_title'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.conditionKey.tr(),
                  style: TextStyle(fontSize: 14, color: colors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  'weather_temp_range'.tr(args: [minT, maxT]),
                  style:
                      TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          _RainProbBadge(prob: data.rainProb),
        ],
      ),
    );
  }
}

class _RainProbBadge extends StatelessWidget {
  final int prob;

  const _RainProbBadge({required this.prob});

  Color _color() {
    if (prob >= 70) return const Color(0xFF1565C0);
    if (prob >= 40) return const Color(0xFF42A5F5);
    return const Color(0xFF90CAF9);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.water_drop, color: _color(), size: 20),
        const SizedBox(height: 2),
        Text(
          '$prob%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _color(),
          ),
        ),
      ],
    );
  }
}
