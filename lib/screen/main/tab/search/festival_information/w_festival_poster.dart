import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_star_rating_row.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/calendar_helper.dart';
import 'package:feple/common/util/kakao_map_launcher.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:feple/common/util/share_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/store_links.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../model/poster_cert_state.dart';
import '../../../../../model/festival_model.dart';
import 'festival_poster_notifier.dart';
import 'festival_poster_style.dart';
import 'w_certification_bottom_sheet.dart';
import 'w_festival_action_button.dart';
import 'w_festival_reviews_sheet.dart';
import 'w_festival_share_card.dart';
import 'w_ticket_link_sheet.dart';
import 'w_weather_bottom_sheet.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.poster, this.heroTag});

  final FestivalModel poster;
  final String? heroTag;

  @override
  State<FestivalPoster> createState() => FestivalPosterState();
}

class FestivalPosterState extends State<FestivalPoster>
    with RefreshableSection<FestivalPoster> {
  late final FestivalPosterNotifier _notifier;
  bool _isSheetOpen = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _notifier = FestivalPosterNotifier(
      poster: widget.poster,
      certService: sl<CertificationService>(),
      festivalService: sl<FestivalInteractionService>(),
      detailService: sl<FestivalDetailService>(),
      onError: (key) {
        if (mounted) context.showErrorSnackbar(key.tr());
      },
    );
    _notifier.init();
  }

  // FestivalInformationFragment가 상세 재조회 후 새 FestivalModel로 다시
  // 그려주면 그 결과를 반영한다 — FestivalPoster 자신은 재조회하지 않는다
  // (같은 festivalId를 화면 진입마다 두 번 조회하지 않기 위함).
  @override
  void didUpdateWidget(FestivalPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poster != widget.poster) {
      _notifier.updatePoster(widget.poster);
    }
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> refresh() => _notifier.init();

  @override
  Future<void> refreshSection() => refresh();

  Future<void> _openKakaoMap() => openKakaoMap(
    context,
    latitude: _notifier.poster.latitude,
    longitude: _notifier.poster.longitude,
    locationName: _notifier.poster.location,
  );

  Future<void> _addToCalendar() => CalendarHelper.addToDeviceCalendar(
    context,
    title: _notifier.poster.displayTitle(context.isEnglish),
    startDate: _notifier.poster.startDate,
    endDate: _notifier.poster.endDate,
    description: _notifier.poster.description,
    location: _notifier.poster.location,
  );

  void _withHaptic(VoidCallback fn) {
    HapticFeedback.lightImpact();
    fn();
  }

  // 좋아요·참석 등 로그인이 필요한 토글 — 비로그인이면 로그인 안내 후 중단한다.
  void _withLoginAndHaptic(VoidCallback fn) {
    if (!ensureLoggedIn(context)) return;
    _withHaptic(fn);
  }

  // 포스터 이미지+정보를 합성한 카드 이미지와 앱 링크를 텍스트와 함께 공유한다.
  // 카드 생성이 실패해도(네트워크 오류 등) 텍스트+링크만으로는 공유되게 한다.
  Future<void> _shareFestival() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    final isEnglish = context.isEnglish;
    final text =
        '${_notifier.poster.displayTitle(isEnglish)}\n${_notifier.poster.location}\n${_notifier.poster.startDate}'
        '\n\n${'share_festival_cta'.tr()}\n$kAppDownloadUrl';
    try {
      final ok = await shareContent(
        context,
        text: text,
        cardToCapture: FestivalShareCard(poster: _notifier.poster, isEnglish: isEnglish),
        precacheImageUrl: _notifier.poster.posterUrl,
        captureFileName: 'feple_festival.png',
        logTag: 'FestivalPoster',
      );
      if (!ok && mounted) context.showErrorSnackbar('share_failed'.tr());
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// 한 번에 하나의 시트만 열리도록 가드하고, 닫히면 가드를 푼다.
  void _openSheet(Widget child) {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    showAppBottomSheet(
      context,
      isScrollControlled: false,
      builder: (_) => child,
    ).whenComplete(() {
      if (mounted) _isSheetOpen = false;
    });
  }

  void _showWeather() => _openSheet(WeatherBottomSheet(
        festivalId: _notifier.festivalId,
        startDate: _notifier.poster.startDate,
        endDate: _notifier.poster.endDate,
      ));

  void _showTicketLinks() =>
      _openSheet(TicketLinkSheet(links: _notifier.ticketLinks));

  VoidCallback? _certButtonTap() => switch (_notifier.certState) {
    PosterCertState.certified => () => context.showInfoSnackbar(
      'cert_already_approved'.tr(),
    ),
    PosterCertState.pending => () => context.showInfoSnackbar(
      'cert_pending_notice'.tr(),
    ),
    PosterCertState.none => _submitCertification,
  };

  IconData _certButtonIcon() => _notifier.certState.icon;

  Color _certButtonColor(AbstractThemeColors colors) =>
      _notifier.certState.color(colors);

  Color? _certButtonBgColor(AbstractThemeColors colors) =>
      _notifier.certState.bgColor(colors);

  Future<void> _submitCertification() async {
    if (!ensureLoggedIn(context)) return;
    await showAppBottomSheet(
      context,
      builder: (ctx) => CertificationBottomSheet(
        festivalName: _notifier.poster.displayTitle(context.isEnglish),
        festivalId: _notifier.festivalId,
        certService: sl<CertificationService>(),
      ),
    );
    if (mounted) unawaited(_notifier.loadMyCertificationStatus());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // poster(제목/설명/날짜/위치 등)는 refreshPoster()로 뒤늦게 통째로 교체될
    // 수 있으므로 posterChanges를 구독해 최신 값으로 다시 그린다. 좋아요·참석
    // 등 나머지 상태는 각자의 좁은 리스너블을 그대로 쓰므로 이 래핑과 무관하게
    // 불필요한 리빌드가 늘어나지 않는다.
    return ListenableBuilder(
      listenable: _notifier.posterChanges,
      builder: (context, _) {
        final hasDescription = _notifier.poster.description.isNotEmpty;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ..._buildBackground(colors),
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppDimens.appBarHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoRow(colors),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ListenableBuilder(
                        listenable: _notifier.actionButtonsChanges,
                        builder: (_, _) => _buildActionButtons(colors),
                      ),
                    ),
                    if (hasDescription)
                      ListenableBuilder(
                        listenable: _notifier,
                        builder: (_, _) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildDescriptionSection(colors),
                        ),
                      ),
                    if (!hasDescription) const SizedBox(height: AppDimens.space8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildBackground(AbstractThemeColors colors) => [
    Positioned.fill(
      child: ClipRect(
        child: CachedNetworkImage(
          imageUrl: _notifier.poster.posterUrl,
          memCacheWidth: 100,
          fit: BoxFit.cover,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
          placeholder: (_, _) => const ColoredBox(color: Colors.black26),
          errorWidget: (_, _, _) => const ColoredBox(color: Colors.black26),
        ),
      ),
    ),
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: -5, // Stack 하단 경계의 1px 틈 방지
      child: ColoredBox(color: colors.swiperOverlay.withValues(alpha: 0.55)),
    ),
  ];

  Widget _buildInfoRow(AbstractThemeColors colors) {
    // 2:3 비율(120x180 기준) 유지하며 화면 너비에 비례 — SingleChildScrollView
    // 안이라 오버플로우 위험 없이 캡 없는 ResponsiveSize 사용 가능.
    final posterWidth = ResponsiveSize(context).w(120);
    final posterHeight = posterWidth * 1.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPosterThumbnail(colors, posterWidth, posterHeight),
          const SizedBox(width: AppDimens.space16),
          Expanded(child: _buildInfoColumn(colors)),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    if (!_notifier.ratingLoaded) return const SizedBox.shrink();
    if (_notifier.ratingLoadFailed) return const SizedBox.shrink();

    final hasRating = _notifier.ratingCount > 0;
    final label = hasRating
        ? 'rating_average_label'.tr(
            args: [
              _notifier.averageRating.toStringAsFixed(1),
              _notifier.ratingCount.toString(),
            ],
          )
        : 'reviews_no_reviews'.tr();
    final content = hasRating
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRatingRow(rating: _notifier.averageRating, size: 18),
              const SizedBox(width: AppDimens.space4),
              Text(
                '(${_notifier.ratingCount})',
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXxs,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (_) => const Icon(
                Icons.star_outline_rounded,
                color: Colors.white60,
                size: 18,
              ),
            ),
          );

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: _showReviews,
        // 별 아이콘/텍스트만큼만 히트 영역이 생기면 최소 터치 타겟보다 작아져
        // 탭하기 어려우므로 세로로 최소 44dp를 확보한다.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
          child: Align(alignment: Alignment.centerLeft, child: content),
        ),
      ),
    );
  }

  void _showReviews() {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    final isEn = context.isEnglish;
    showAppBottomSheet(
      context,
      builder: (_) => FestivalReviewsSheet(
        festivalId: _notifier.festivalId,
        certService: sl<CertificationService>(),
        certState: _notifier.certState,
        festivalTitle: _notifier.poster.displayTitle(isEn),
        certId: _notifier.certId,
        initialRating: _notifier.myRating,
        initialReview: _notifier.myReview,
        onCertTap: _submitCertification,
      ),
    ).whenComplete(() {
      if (mounted) {
        _isSheetOpen = false;
        _notifier.loadRatingInfo();
      }
    });
  }

  Widget _buildPosterThumbnail(AbstractThemeColors colors, double width, double height) {
    final child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        boxShadow: CardShadows.elevated(colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        child: CachedNetworkImage(
          imageUrl: _notifier.poster.posterUrl,
          memCacheWidth: 300,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const SkeletonBox(height: double.infinity),
          errorWidget: (_, _, _) => Container(
            color: colors.surface,
            child: Icon(
              Icons.broken_image_rounded,
              size: 32,
              color: colors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
    if (widget.heroTag == null) return child;
    return Hero(tag: widget.heroTag!, child: child);
  }

  Widget _buildInfoColumn(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimens.space4),
        Text(
          _notifier.poster.displayTitle(context.isEnglish),
          softWrap: true,
          style: const TextStyle(
            fontSize: AppDimens.fontSizeTitle,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        _buildTagRow(),
        const SizedBox(height: AppDimens.space8),
        _buildPosterInfoRow(
          icon: Icons.calendar_today_rounded,
          color: colors.accentColor,
          child: Text(
            _notifier.poster.endDate.isNotEmpty
                ? '${_notifier.poster.startDate} ~ ${_notifier.poster.endDate}'
                : _notifier.poster.startDate,
            style: const TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space6),
        GestureDetector(
          onTap: _openKakaoMap,
          child: _buildPosterInfoRow(
            icon: Icons.location_on_rounded,
            color: colors.accentColor,
            child: Text(
              _notifier.poster.location,
              softWrap: true,
              style: const TextStyle(
                fontSize: AppDimens.fontSizeMd,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        _buildInfoColumnBottom(colors),
      ],
    );
  }

  // attending row를 attendingChanges로 개별 구독 — 참석 토글이 다른 정보까지
  // 리빌드시키지 않게 함. 초기화 에러는 여러 로더가 공통으로 건드리므로 전체
  // notifier 구독 유지(자주 발생하지 않고 위젯도 가벼움). 평점 배지는 원래
  // 포스터 썸네일 아래(왼쪽 칸)에 있었는데, 참석예정 바로 아래로 옮겨왔다.
  Widget _buildInfoColumnBottom(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: _notifier.attendingChanges,
          builder: (_, _) => _buildAttendingRow(colors),
        ),
        ListenableBuilder(
          listenable: _notifier,
          builder: (_, _) => _notifier.hasInitError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildInitErrorRow(),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppDimens.space6),
        ListenableBuilder(
          listenable: _notifier,
          builder: (_, _) => _buildRatingBadge(),
        ),
      ],
    );
  }

  Widget _buildPosterInfoRow({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: AppDimens.space6),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildTagRow() {
    final tags = <Widget>[];

    for (final genre in _notifier.poster.genres) {
      final key = genreI18nKey(genre);
      if (key == null) continue;
      tags.add(_Tag(label: key.tr()));
    }

    final age = _notifier.poster.ageRestriction;
    if (age != null && age != 'NONE') {
      final key = ageI18nKey(age);
      if (key != null) {
        tags.add(_Tag(label: key.tr(), color: ageDisplayColor(age)));
      }
    }

    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: tags);
  }

  Widget _buildAttendingRow(AbstractThemeColors colors) {
    final count = _notifier.attendingCount;
    final isAttending = _notifier.attending;
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, color: colors.accentColor, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            count > 0
                ? 'attending_count'.tr(args: ['$count'])
                : 'attend_none'.tr(),
            style: const TextStyle(
              fontSize: AppDimens.fontSizeSm,
              color: Colors.white70,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _withLoginAndHaptic(_notifier.toggleAttending),
          child: AnimatedContainer(
            duration: AppDimens.animFast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isAttending
                  ? colors.accentColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(
                color: isAttending
                    ? colors.accentColor
                    : Colors.white.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Text(
              'attend_toggle'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                fontWeight: FontWeight.w600,
                color: isAttending ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitErrorRow() {
    return GestureDetector(
      onTap: _notifier.retryInit,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            size: 13,
            color: Colors.white54,
          ),
          const SizedBox(width: AppDimens.space4),
          Text(
            'retry'.tr(),
            style: const TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: Colors.white54,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AbstractThemeColors colors) {
    final hasTicketLinks = _notifier.ticketLinks.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: FestivalActionButton(
            onTap: () => _withLoginAndHaptic(_notifier.toggleLike),
            icon: _notifier.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _notifier.liked ? colors.likeActiveColor : Colors.white,
            bgColor: _notifier.liked
                ? colors.likeActiveColor.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.15),
            label: 'action_like'.tr(),
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: _shareFestival,
            icon: Icons.share_outlined,
            label: 'action_share'.tr(),
            isLoading: _isSharing,
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: _showWeather,
            icon: Icons.cloud_outlined,
            label: 'action_weather'.tr(),
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: _addToCalendar,
            icon: Icons.event_available_rounded,
            label: 'action_calendar'.tr(),
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: _certButtonTap(),
            icon: _certButtonIcon(),
            color: _certButtonColor(colors),
            bgColor: _certButtonBgColor(colors),
            label: 'action_cert'.tr(),
          ),
        ),
        if (hasTicketLinks)
          Expanded(
            child: FestivalActionButton(
              onTap: _showTicketLinks,
              icon: Icons.confirmation_number_outlined,
              label: 'action_ticket'.tr(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDescriptionSection(AbstractThemeColors colors) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
    ),
    GestureDetector(
      onTap: _notifier.toggleDesc,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: AppDimens.space6),
            Text(
              'festival_info'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Icon(
              _notifier.descExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    ),
    // 접기 애니메이션: Text는 항상 full-width로 레이아웃되고(리플로우 없음),
    // ClipRect + AnimatedAlign(heightFactor)가 높이만 1→0으로 줄여 위로 밀어 올린다.
    // (예전엔 AnimatedCrossFade의 secondChild 너비를 full-width로 맞춰 회피했는데,
    //  두 child가 같은 너비를 보고해야만 동작하는 취약한 방식이었다.)
    ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topLeft,
        heightFactor: _notifier.descExpanded ? 1.0 : 0.0,
        duration: AppDimens.animFast,
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Text(
            _notifier.poster.description,
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    ),
    const SizedBox(height: AppDimens.space10),
  ];
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXxs,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
