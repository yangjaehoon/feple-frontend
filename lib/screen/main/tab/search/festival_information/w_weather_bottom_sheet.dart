import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/screen/main/tab/search/festival_information/weather_style.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class WeatherBottomSheet extends StatefulWidget {
  final int festivalId;
  final String startDate; // "YYYY-MM-DD"
  final String endDate;   // "YYYY-MM-DD" or empty

  const WeatherBottomSheet({
    super.key,
    required this.festivalId,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<WeatherBottomSheet> createState() => _WeatherBottomSheetState();
}

class _WeatherBottomSheetState extends State<WeatherBottomSheet> {
  late Future<WeatherModel?> _future;
  bool _tooEarly = false;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    final start = DateTime.tryParse(widget.startDate);
    final end = widget.endDate.isNotEmpty ? DateTime.tryParse(widget.endDate) : null;
    final isEnded = end != null && end.isBefore(DateTime(today.year, today.month, today.day));
    final daysUntilStart = start != null
        ? start.difference(DateTime(today.year, today.month, today.day)).inDays
        : 0;

    // 종료된 페스티벌은 DB에서 바로 조회, 미래 페스티벌은 3일 이내만 가능
    if (!isEnded && daysUntilStart > 3) {
      _tooEarly = true;
      _future = Future.value(null);
    } else {
      _future = sl<FestivalDetailService>().fetchWeather(widget.festivalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: 20),
          Text(
            'weather_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 20),
          if (_tooEarly)
            const _TooEarlyMessage()
          else
            _buildWeatherFuture(colors),
        ],
      ),
    );
  }

  Widget _buildWeatherFuture(AbstractThemeColors colors) {
    return FutureBuilder<WeatherModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: colors.activate),
          );
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'err_fetch_data'.tr(),
            onRetry: () => setState(() {
              _future = sl<FestivalDetailService>().fetchWeather(widget.festivalId);
            }),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const _NoDataMessage();
        }
        return _buildWeatherData(data, colors);
      },
    );
  }

  Widget _buildWeatherData(WeatherModel data, AbstractThemeColors colors) {
    final minT = data.minTemp.toStringAsFixed(0);
    final maxT = data.maxTemp.toStringAsFixed(0);

    return Column(
      children: [
        Text(data.conditionIcon, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        Text(
          data.conditionKey.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxl,
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
              color: AppColors.notificationReminder,
            ),
            const SizedBox(width: 12),
            _InfoChip(
              icon: Icons.water_drop_rounded,
              label: 'weather_rain_prob'.tr(args: ['${data.rainProb}']),
              color: rainProbColor(data.rainProb),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

}

class _TooEarlyMessage extends StatelessWidget {
  const _TooEarlyMessage();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 48, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'weather_too_early'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.text,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'weather_too_early_hint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  const _NoDataMessage();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'weather_no_data'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textSecondary),
          ),
        ],
      ),
    );
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  color: colors.text,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
