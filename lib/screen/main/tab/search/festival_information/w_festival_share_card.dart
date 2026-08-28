import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/common/widget/w_share_card_parts.dart';
import 'package:feple/model/festival_model.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/constant/app_dimensions.dart';

/// 공유용으로 캡처되는 고정 크기 카드 — 앱 테마와 무관하게 항상 같은 모습으로 그려진다.
class FestivalShareCard extends StatelessWidget {
  final FestivalModel poster;
  final bool isEnglish;

  const FestivalShareCard({super.key, required this.poster, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: shareCardWidth,
      height: shareCardHeight,
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
          const Positioned(top: 16, right: 16, child: FepleBrandBadge()),
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
                ShareCardInfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: poster.endDate.isNotEmpty
                      ? '${poster.startDate} ~ ${poster.endDate}'
                      : poster.startDate,
                ),
                const SizedBox(height: AppDimens.space4),
                ShareCardInfoRow(icon: Icons.location_on_rounded, text: poster.location),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
