import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_config.dart';
import 'package:flutter/material.dart';

class ScheduleListTile extends StatelessWidget {
  final ArtistScheduleModel item;
  final VoidCallback? onTap;
  final bool isPast;

  const ScheduleListTile({
    super.key,
    required this.item,
    this.onTap,
    this.isPast = false,
  });

  // 지난 일정에 적용하는 투명도 — Opacity 위젯으로 전체를 감싸면 saveLayer()가 발생해
  // 리스트 항목마다 GPU offscreen buffer가 생긴다. 색상에 직접 alpha를 녹여 방지한다.
  static const double _pastAlpha = 0.55;

  Color _c(Color base) => isPast ? base.withValues(alpha: _pastAlpha) : base;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPoster(colors),
            const SizedBox(width: 12),
            Expanded(child: _buildContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(AbstractThemeColors colors) {
    final typeConfig = getEventTypeConfig(item.eventType, colors);
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    // 포스터 이미지는 색상 속성으로 alpha를 적용할 수 없으므로 42×42px 범위에만 Opacity 사용
    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: hasPoster
          ? CachedNetworkImage(
              imageUrl: item.posterUrl!,
              width: 42,
              height: 42,
              memCacheWidth: 84,
              fit: BoxFit.cover,
              fadeInDuration: AppDimens.animXFast,
              fadeOutDuration: AppDimens.animTapFeedback,
              errorWidget: (_, __, ___) => EventTypeIcon(config: typeConfig),
            )
          : EventTypeIcon(config: typeConfig),
    );
    return isPast ? Opacity(opacity: _pastAlpha, child: poster) : poster;
  }

  Widget _buildContent(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w700,
            color: _c(colors.textTitle),
          ),
        ),
        if (item.location != null && item.location!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.location!,
            style: TextStyle(fontSize: AppDimens.fontSizeXs, color: _c(colors.textSecondary)),
          ),
        ],
        if (item.startDate != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 11, color: _c(colors.textSecondary)),
              const SizedBox(width: 4),
              Text(
                item.dateRange,
                style: TextStyle(fontSize: AppDimens.fontSizeXs, color: _c(colors.textSecondary)),
              ),
            ],
          ),
        ],
        if (item.coArtists.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildCoArtists(colors),
        ],
      ],
    );
  }

  Widget _buildCoArtists(AbstractThemeColors colors) {
    return SizedBox(
      height: 28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: item.coArtists.length,
        itemBuilder: (_, index) {
          final coArtist = item.coArtists[index];
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: coArtist.artistName,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: _c(colors.backgroundMain),
                backgroundImage: (coArtist.profileImageUrl != null && coArtist.profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(coArtist.profileImageUrl!, maxWidth: 52)
                    : null,
                child: (coArtist.profileImageUrl == null || coArtist.profileImageUrl!.isEmpty)
                    ? Icon(Icons.person_rounded, size: 12, color: _c(colors.textSecondary))
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
