import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/common/widget/w_share_card_parts.dart';
import 'package:feple/model/festival_model.dart';
import 'package:flutter/material.dart';

/// 공유용으로 캡처되는 고정 크기 카드 — 앱 테마와 무관하게 항상 같은 모습으로 그려진다.
class FestivalShareCard extends StatelessWidget {
  final FestivalModel poster;
  final bool isEnglish;

  const FestivalShareCard({super.key, required this.poster, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return ShareCardFrame(
      imageUrl: poster.posterUrl,
      title: poster.displayTitle(isEnglish),
      topLeft: !poster.isEnded && poster.dDaysUntil != null
          ? DayBadge(dDays: poster.dDaysUntil!)
          : null,
      infoRows: [
        ShareCardInfoRow(
          icon: Icons.calendar_today_rounded,
          text: poster.endDate.isNotEmpty
              ? '${poster.startDate} ~ ${poster.endDate}'
              : poster.startDate,
        ),
        ShareCardInfoRow(icon: Icons.location_on_rounded, text: poster.location),
      ],
    );
  }
}
