import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/navigate_after_fetch.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_status_filter_chip.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_tap_loading_indicator.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

import 'cert_status_style.dart';
import 'filtered_status_list_state.dart';
import 'w_rating_sheet.dart';
import 'w_status_badge.dart';
import 'w_submit_certification_sheet.dart';
import 'package:feple/common/util/forced_refresh.dart';

class CertificationListScreen extends StatefulWidget {
  const CertificationListScreen({super.key});

  @override
  State<CertificationListScreen> createState() =>
      _CertificationListScreenState();
}

class _CertificationListScreenState extends State<CertificationListScreen>
    with
        FilteredStatusListState<CertificationModel, CertStatus,
            CertificationListScreen> {
  final _certService = sl<CertificationService>();

  @override
  Future<List<CertificationModel>> fetchItems() =>
      _certService.getMyCertifications();

  @override
  CertStatus statusOf(CertificationModel item) => item.status;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  /// 에러·빈 상태를 RefreshIndicator가 감지할 수 있도록 스크롤 가능하게 감쌉니다.
  Widget _buildScrollable(Widget child) => RefreshableCenter(child: child);

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space10),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SkeletonBox(
              width: MediaQuery.sizeOf(context).width * 0.231, // 90/390
              height: MediaQuery.sizeOf(context).width * 0.231,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 15),
                    SizedBox(height: AppDimens.space8),
                    SkeletonBox(
                      width: 80,
                      height: 22,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    SizedBox(height: AppDimens.space6),
                    SkeletonBox(width: 60, height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSubmitSheet() async {
    final result = await showAppBottomSheet<bool>(
      context,
      builder: (_) => SubmitCertificationSheet(certService: _certService),
    );
    if (result == true) unawaited(loadItems());
  }

  Widget _buildFilterChips() {
    return StatusFilterChipRow<CertStatus>(
      values: CertStatus.values,
      selected: filter,
      allLabel: 'filter_all'.tr(),
      labelOf: (status) => status.labelKey.tr(),
      colorOf: (status, colors) => status.displayColor(colors),
      onChanged: (status) => setState(() => filter = status),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    final displayed = filteredItems;
    return RefreshIndicator(
      onRefresh: () => withForcedRefresh(refreshItems),
      color: colors.activate,
      child: isLoadingItems
          ? _buildSkeleton(colors)
          : hasLoadError
          ? _buildScrollable(ErrorState.network(loadError!, onRetry: loadItems))
          : displayed.isEmpty
          ? _buildScrollable(
              EmptyState(
                icon: Icons.verified_outlined,
                title: 'cert_no_history'.tr(),
                subtitle: filter == null ? 'cert_no_history_hint'.tr() : null,
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: displayed.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space10),
              itemBuilder: (context, index) {
                final cert = displayed[index];
                return AnimatedListItem(
                  index: index,
                  child: _CertCard(
                    key: ValueKey(cert.id),
                    cert: cert,
                    certService: _certService,
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: SecondaryAppBar(
        title: 'festival_certification'.tr(),
        actions: [
          TextButton.icon(
            onPressed: _openSubmitSheet,
            // certRingColor(skyBlue)는 appBarColor와 동일한 색이라 앱바 위에서 안 보임 —
            // 앱바 텍스트/아이콘 전용 색상 사용
            icon: Icon(
              Icons.add_photo_alternate_rounded,
              color: colors.appBarIconColor,
              size: 20,
            ),
            label: Text(
              'cert_submit'.tr(),
              style: TextStyle(
                color: colors.appBarIconColor,
                fontWeight: FontWeight.w700,
                fontSize: AppDimens.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }
}

class _CertCard extends StatefulWidget {
  final CertificationModel cert;
  final CertificationService certService;

  const _CertCard({super.key, required this.cert, required this.certService});

  @override
  State<_CertCard> createState() => _CertCardState();
}

class _CertCardState extends State<_CertCard> with NavigationGuard {
  late int? _rating;
  late String? _review;
  bool _isSubmitting = false;
  // 포스터 탭 → fetchById → 화면 전환까지 아무 피드백 없이 멈춰 보이는 걸 방지
  bool _isLoadingFestival = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.cert.myRating;
    _review = widget.cert.myReview;
  }

  Future<void> _navigateToFestival() async {
    await guardedNavigate(() => navigateAfterFetch(
      context,
      fetch: () => sl<FestivalService>().fetchById(widget.cert.festivalId),
      builder: (festival) => FestivalInformationFragment(poster: festival),
      setLoading: (v) {
        if (mounted) setState(() => _isLoadingFestival = v);
      },
      errorTag: 'CertCard',
    ));
  }

  Future<void> _openRatingSheet() async {
    if (_isSubmitting) return;
    final result = await showAppBottomSheet<({int rating, String? review})>(
      context,
      builder: (_) => RatingSheet(
        festivalTitle: widget.cert.displayFestivalTitle(context.isEnglish),
        initialRating: _rating,
        initialReview: _review,
      ),
    );
    if (result == null) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.certService.submitRating(
        widget.cert.id,
        result.rating,
        result.review,
      );
      if (mounted) {
        setState(() {
          _rating = result.rating;
          _review = result.review;
          _isSubmitting = false;
        });
        context.showInfoSnackbar('rating_submit_success'.tr());
      }
    } catch (e) {
      debugPrint('[CertCard] 별점 저장 실패: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        context.showErrorSnackbar('rating_submit_failed'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isApproved = widget.cert.status == CertStatus.approved;
    final isPending = widget.cert.status == CertStatus.pending;
    final statusColor = widget.cert.status.displayColor(colors);
    final statusLabel = widget.cert.status.labelKey.tr();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        boxShadow: CardShadows.subtle(colors),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPosterImage(widget.cert.posterUrl, colors),
          _buildCardContent(
            colors,
            statusColor,
            statusLabel,
            isApproved,
            isPending,
          ),
        ],
      ),
    );
  }

  Widget _buildPosterImage(String? posterUrl, AbstractThemeColors colors) {
    final posterWidth = MediaQuery.sizeOf(context).width * 0.231; // 90/390
    return GestureDetector(
      onTap: _isLoadingFestival ? null : _navigateToFestival,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        child: SizedBox(
          width: posterWidth,
          height: posterWidth * 1.5, // 135/90 = 1.5 (2:3 비율)
          child: _isLoadingFestival
              ? const Center(child: TapLoadingIndicator())
              : posterUrl != null
              ? CachedNetworkImage(
                  imageUrl: posterUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 180,
                  fadeInDuration: AppDimens.animXFast,
                  fadeOutDuration: AppDimens.animTapFeedback,
                  placeholder: (_, _) =>
                      const SkeletonBox(height: double.infinity),
                  errorWidget: (_, _, _) => _buildPhotoPlaceholder(colors),
                )
              : _buildPhotoPlaceholder(colors),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color statusColor, String statusLabel) {
    return StatusBadge(
      color: statusColor,
      label: statusLabel,
      backgroundAlpha: 0.15,
      borderRadius: AppDimens.cardRadius,
      fontSize: AppDimens.fontSizeXs,
    );
  }

  Widget _buildCardContent(
    AbstractThemeColors colors,
    Color statusColor,
    String statusLabel,
    bool isApproved,
    bool isPending,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cert.displayFestivalTitle(context.isEnglish),
              style: TextStyle(
                fontSize: AppDimens.fontSizeLg,
                fontWeight: FontWeight.w700,
                color: colors.textTitle,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimens.space6),
            _buildStatusBadge(statusColor, statusLabel),
            _buildMeta(
              isPending,
              isApproved,
              widget.cert.rejectionMessage,
              widget.cert.formattedDate,
              colors,
            ),
            if (isApproved) ...[
              const SizedBox(height: AppDimens.space6),
              _buildRatingSection(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(AbstractThemeColors colors) {
    if (_isSubmitting) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.activate,
        ),
      );
    }
    if (_rating != null) {
      return Semantics(
        button: true,
        label: '${'rating_star_label'.tr(args: ['$_rating'])} · ${'reviews_edit_rating'.tr()}',
        child: GestureDetector(
          onTap: _openRatingSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < _rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
              if (_review != null && _review!.isNotEmpty) ...[
                const SizedBox(width: AppDimens.space6),
                Flexible(
                  child: Text(
                    _review!,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXxs,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _openRatingSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 14, color: colors.activate),
          const SizedBox(width: AppDimens.space4),
          Text(
            'rating_submit'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              fontWeight: FontWeight.w600,
              color: colors.activate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(
    bool isPending,
    bool isApproved,
    String? rejectionMessage,
    String? createdAt,
    AbstractThemeColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isPending &&
            !isApproved &&
            rejectionMessage != null &&
            rejectionMessage.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            'cert_rejection_reason'.tr(args: [rejectionMessage]),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (createdAt != null) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            createdAt,
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoPlaceholder(AbstractThemeColors colors) {
    return Container(
      color: colors.certRingColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.photo_rounded,
        color: colors.textSecondary.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }
}
