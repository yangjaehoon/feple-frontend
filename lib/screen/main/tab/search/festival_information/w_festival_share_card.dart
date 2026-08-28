import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/model/festival_model.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/constant/app_dimensions.dart';

/// 공유용으로 캡처되는 고정 크기 카드 — 앱 테마와 무관하게 항상 같은 모습으로 그려진다.
class FestivalShareCard extends StatelessWidget {
  static const double width = 360;
  static const double height = 540;

  final FestivalModel poster;
  final bool isEnglish;

  const FestivalShareCard({super.key, required this.poster, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: CachedNetworkImageProvider(poster.posterUrl), fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          if (!poster.isEnded && poster.dDaysUntil != null)
            Positioned(top: 16, left: 16, child: DayBadge(dDays: poster.dDaysUntil!)),
          Positioned(top: 16, right: 16, child: _buildBrandBadge()),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  poster.displayTitle(isEnglish),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppDimens.space10),
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  poster.endDate.isNotEmpty ? '${poster.startDate} ~ ${poster.endDate}' : poster.startDate,
                ),
                const SizedBox(height: AppDimens.space4),
                _buildInfoRow(Icons.location_on_rounded, poster.location),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 흰색 핀 로고(투명 배경) — 어두운 배지 위에서 선명하게 보인다.
          Image.asset(
            'assets/image/feple_clear_960.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            cacheWidth: 60,
          ),
          const SizedBox(width: AppDimens.space4),
          const Text(
            'Feple',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: AppDimens.space6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
