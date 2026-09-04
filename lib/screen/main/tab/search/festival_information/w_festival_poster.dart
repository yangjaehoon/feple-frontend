import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../model/festival_model.dart';
import 'festival_poster_notifier.dart';
import 'w_certification_bottom_sheet.dart';
import 'w_festival_action_buttons_row.dart';
import 'w_festival_description.dart';
import 'w_festival_poster_info.dart';
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
    // UserProvider가 없는 컨텍스트(일부 위젯 테스트)에서는 게스트로 보지 않는다(기존 동작).
    final userProvider = context.read<UserProvider?>();
    _notifier = FestivalPosterNotifier(
      poster: widget.poster,
      certService: sl<CertificationService>(),
      festivalService: sl<FestivalInteractionService>(),
      detailService: sl<FestivalDetailService>(),
      isGuest: userProvider != null && userProvider.currentUserId == null,
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

  // 좋아요·참석 등 로그인이 필요한 토글 — 비로그인이면 로그인 화면으로 유도하고,
  // 로그인에 성공하면 원래 누르려던 토글을 곧바로 실행한다.
  Future<void> _withLoginAndHaptic(VoidCallback fn) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
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

  Future<void> _submitCertification() async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
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
                    FestivalPosterInfo(
                      notifier: _notifier,
                      heroTag: widget.heroTag,
                      onKakaoMap: _openKakaoMap,
                      onToggleAttending: () =>
                          _withLoginAndHaptic(_notifier.toggleAttending),
                      onShowReviews: _showReviews,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ListenableBuilder(
                        listenable: _notifier.actionButtonsChanges,
                        builder: (_, _) => FestivalActionButtonsRow(
                          liked: _notifier.liked,
                          isSharing: _isSharing,
                          certState: _notifier.certState,
                          ticketLinks: _notifier.ticketLinks,
                          onToggleLike: () =>
                              _withLoginAndHaptic(_notifier.toggleLike),
                          onShare: _shareFestival,
                          onWeather: _showWeather,
                          onCalendar: _addToCalendar,
                          onTicketLinks: _showTicketLinks,
                          onSubmitCert: _submitCertification,
                        ),
                      ),
                    ),
                    if (hasDescription)
                      ListenableBuilder(
                        listenable: _notifier,
                        builder: (_, _) => FestivalDescriptionSection(
                          description: _notifier.poster.description,
                          expanded: _notifier.descExpanded,
                          onToggle: _notifier.toggleDesc,
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
}
