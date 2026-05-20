import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/air_quality_model.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

class FestivalAirQuality extends StatefulWidget {
  final int festivalId;

  const FestivalAirQuality({super.key, required this.festivalId});

  @override
  State<FestivalAirQuality> createState() => _FestivalAirQualityState();
}

class _FestivalAirQualityState extends State<FestivalAirQuality> {
  late Future<AirQualityModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<FestivalService>().fetchAirQuality(widget.festivalId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<AirQualityModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingHorizontal,
            vertical: AppDimens.paddingVertical,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'aqi_label'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.sidoName} · ${data.stationName} · ${data.dataTime}',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AqiItem(
                      label: 'fine_dust'.tr(),
                      value: data.pm10Value,
                      unit: 'μg/m³',
                      grade: data.pm10Grade,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AqiItem(
                      label: 'ultra_fine_dust'.tr(),
                      value: data.pm25Value,
                      unit: 'μg/m³',
                      grade: data.pm25Grade,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AqiItem(
                      label: 'aqi_label'.tr(),
                      value: data.khaiValue,
                      unit: '',
                      grade: data.khaiGrade,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AqiItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String grade;

  const _AqiItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.grade,
  });

  Color _gradeColor() {
    return switch (grade) {
      '1' => const Color(0xFF4CAF50),
      '2' => const Color(0xFFFFC107),
      '3' => const Color(0xFFFF9800),
      '4' => const Color(0xFFF44336),
      _ => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final gradeColor = _gradeColor();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: gradeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gradeColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$value${unit.isNotEmpty ? ' $unit' : ''}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: gradeColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AirQualityModel.gradeKey(grade).tr(),
            style: TextStyle(fontSize: 10, color: gradeColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
