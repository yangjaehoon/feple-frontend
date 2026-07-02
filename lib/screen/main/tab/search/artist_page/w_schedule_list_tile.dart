import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_icon.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/festival_service.dart';
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
            _buildPoster(context, colors),
            const SizedBox(width: 12),
            Expanded(child: _buildContent(context, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, AbstractThemeColors colors) {
    final typeConfig = item.eventType.config(colors);
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => _navigateToFestival(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        child: hasPoster
            ? CachedNetworkImage(
                imageUrl: item.posterUrl!,
                width: 42,
                height: 63,
                memCacheWidth: 84,
                memCacheHeight: 126,
                fit: BoxFit.cover,
                // CachedNetworkImage color 파라미터로 alpha 적용 — Opacity 위젯(saveLayer) 불필요
                color: isPast ? Colors.white.withValues(alpha: _pastAlpha) : null,
                colorBlendMode: isPast ? BlendMode.modulate : null,
                fadeInDuration: AppDimens.animXFast,
                fadeOutDuration: AppDimens.animTapFeedback,
                placeholder: (_, __) => EventTypeIcon(config: typeConfig),
                errorWidget: (_, __, ___) => EventTypeIcon(config: typeConfig),
              )
            : EventTypeIcon(config: typeConfig),
      ),
    );
  }

  Future<void> _navigateToFestival(BuildContext context) async {
    try {
      final festival = await sl<FestivalService>().fetchById(item.festivalId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
      );
    } catch (e) {
      debugPrint('[ScheduleListTile] festival fetch error: $e');
    }
  }

  Widget _buildContent(BuildContext context, AbstractThemeColors colors) {
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
          _buildCoArtists(context, colors),
        ],
      ],
    );
  }

  Widget _buildCoArtists(BuildContext context, AbstractThemeColors colors) {
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
              message: coArtist.displayName(context.isEnglish),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  SlideRoute(
                    builder: (_) => ArtistScreen(
                      artistId: coArtist.artistId,
                      artistName: coArtist.artistName,
                      artistNameEn: coArtist.artistNameEn,
                      followerCount: 0,
                      profileImageUrl: coArtist.profileImageUrl,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: ClipOval(
                    child: (coArtist.profileImageUrl != null && coArtist.profileImageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: coArtist.profileImageUrl!,
                            width: 26,
                            height: 26,
                            memCacheWidth: 52,
                            fit: BoxFit.cover,
                            color: isPast ? Colors.white.withValues(alpha: _pastAlpha) : null,
                            colorBlendMode: isPast ? BlendMode.modulate : null,
                          )
                        : Container(
                            color: _c(colors.backgroundMain),
                            child: Icon(Icons.person_rounded, size: 12, color: _c(colors.textSecondary)),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
