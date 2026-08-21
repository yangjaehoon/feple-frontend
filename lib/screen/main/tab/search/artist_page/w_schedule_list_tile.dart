import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/calendar_helper.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_tap_loading_indicator.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:feple/screen/main/tab/search/artist_page/festival_navigation.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_icon.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/bounded_responsive_size.dart';

class ScheduleListTile extends StatefulWidget {
  final ArtistScheduleModel item;
  final VoidCallback? onTap;
  final bool isPast;
  // 부모가 같은 festivalId로 별도 fetch(행 전체 탭)를 진행 중일 때 표시
  final bool isLoading;
  final bool showCalendarAction;

  const ScheduleListTile({
    super.key,
    required this.item,
    this.onTap,
    this.isPast = false,
    this.isLoading = false,
    this.showCalendarAction = false,
  });

  @override
  State<ScheduleListTile> createState() => _ScheduleListTileState();
}

class _ScheduleListTileState extends State<ScheduleListTile>
    with NavigationGuard {
  ArtistScheduleModel get item => widget.item;
  bool get isPast => widget.isPast;

  // 포스터 탭 → fetchById → 화면 전환까지 아무 피드백 없이 멈춰 보이는 걸 방지.
  // widget.isLoading(행 전체 탭)과 합쳐서 둘 중 하나라도 진행 중이면 로딩 표시.
  bool _isLoadingFestival = false;
  bool get _loading => _isLoadingFestival || widget.isLoading;

  // 지난 일정에 적용하는 투명도 — Opacity 위젯으로 전체를 감싸면 saveLayer()가 발생해
  // 리스트 항목마다 GPU offscreen buffer가 생긴다. 색상에 직접 alpha를 녹여 방지한다.
  static const double _pastAlpha = 0.55;

  Color _c(Color base) => isPast ? base.withValues(alpha: _pastAlpha) : base;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: _loading ? null : widget.onTap,
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
            if (widget.showCalendarAction) ...[
              const SizedBox(width: 4),
              _buildCalendarButton(context, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarButton(BuildContext context, AbstractThemeColors colors) {
    return Tooltip(
      message: 'add_to_calendar'.tr(),
      child: IconButton(
        icon: const Icon(Icons.event_available_rounded),
        iconSize: AppDimens.iconSizeLg,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: _c(colors.activate),
        onPressed: () => CalendarHelper.addToDeviceCalendar(
          context,
          title: item.title,
          startDate: item.startDate,
          endDate: item.endDate,
          description: item.description ?? '',
          location: item.location ?? '',
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, AbstractThemeColors colors) {
    final typeConfig = item.eventType.config(colors);
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    // w_artist_schedule.dart의 미리보기 영역은 스크롤 없는 Column이라
    // boundedResponsiveSize로 태블릿급 너비에서의 오버플로를 막는다.
    final posterWidth = boundedResponsiveSize(context, 42);
    final posterHeight = boundedResponsiveSize(context, 63);
    return GestureDetector(
      onTap: _loading ? null : _navigateToFestival,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          child: _loading
              ? const Center(child: TapLoadingIndicator())
              : hasPoster
              ? CachedNetworkImage(
                  imageUrl: item.posterUrl!,
                  width: posterWidth,
                  height: posterHeight,
                  memCacheWidth: 84,
                  fit: BoxFit.cover,
                  // CachedNetworkImage color 파라미터로 alpha 적용 — Opacity 위젯(saveLayer) 불필요
                  color: isPast
                      ? Colors.white.withValues(alpha: _pastAlpha)
                      : null,
                  colorBlendMode: isPast ? BlendMode.modulate : null,
                  fadeInDuration: AppDimens.animXFast,
                  fadeOutDuration: AppDimens.animTapFeedback,
                  placeholder: (_, _) => EventTypeIcon(config: typeConfig),
                  errorWidget: (_, _, _) => EventTypeIcon(config: typeConfig),
                )
              : EventTypeIcon(config: typeConfig),
        ),
      ),
    );
  }

  Future<void> _navigateToFestival() async {
    await guardedNavigate(() async {
      setState(() => _isLoadingFestival = true);
      try {
        await navigateToFestivalById(
          context,
          item.festivalId,
          awaitNavigation: true,
        );
      } finally {
        if (mounted) setState(() => _isLoadingFestival = false);
      }
    });
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.location != null && item.location!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.location!,
            style: TextStyle(
              fontSize: AppDimens.fontSizeXs,
              color: _c(colors.textSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (item.startDate != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: _c(colors.textSecondary),
              ),
              const SizedBox(width: 4),
              Text(
                item.dateRange,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: _c(colors.textSecondary),
                ),
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
    final avatarSize = boundedResponsiveSize(context, 26);
    return SizedBox(
      height: 48,
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
                    builder: (_) => ArtistScreen.fromCoArtist(coArtist),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: ClipOval(
                      child:
                          (coArtist.profileImageUrl != null &&
                              coArtist.profileImageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: coArtist.profileImageUrl!,
                              width: avatarSize,
                              height: avatarSize,
                              memCacheWidth: 52,
                              fit: BoxFit.cover,
                              color: isPast
                                  ? Colors.white.withValues(alpha: _pastAlpha)
                                  : null,
                              colorBlendMode: isPast
                                  ? BlendMode.modulate
                                  : null,
                              placeholder: (_, _) =>
                                  _buildCoArtistFallback(colors),
                              errorWidget: (_, _, _) =>
                                  _buildCoArtistFallback(colors),
                            )
                          : _buildCoArtistFallback(colors),
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

  Widget _buildCoArtistFallback(AbstractThemeColors colors) {
    return Container(
      color: _c(colors.backgroundMain),
      child: Icon(
        Icons.person_rounded,
        size: 12,
        color: _c(colors.textSecondary),
      ),
    );
  }
}
