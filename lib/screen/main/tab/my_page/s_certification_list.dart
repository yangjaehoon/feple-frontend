import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

import 'cert_status_style.dart';
import 'w_rating_sheet.dart';
import 'w_submit_certification_sheet.dart';

class CertificationListScreen extends StatefulWidget {
  const CertificationListScreen({super.key});

  @override
  State<CertificationListScreen> createState() =>
      _CertificationListScreenState();
}

class _CertificationListScreenState extends State<CertificationListScreen> {
  final _certService = sl<CertificationService>();
  List<CertificationModel> _certifications = [];
  bool _loading = true;
  bool _hasError = false;
  CertStatus? _filter; // null = 전체

  List<CertificationModel> get _filtered => _filter == null
      ? _certifications
      : _certifications.where((c) => c.status == _filter).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _certifications = []; _loading = false; _hasError = true; });
    }
  }

  // RefreshIndicator용 — 기존 목록 유지, 스켈레톤 전환 없음
  Future<void> _refresh() async {
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _hasError = false; });
    } catch (_) {}
  }

  /// 에러·빈 상태를 RefreshIndicator가 감지할 수 있도록 스크롤 가능하게 감쌉니다.
  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
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
              width: 90,
              height: 90,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 15),
                    SizedBox(height: 8),
                    SkeletonBox(width: 80, height: 22,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    SizedBox(height: 6),
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
    if (result == true) _load();
  }

  Widget _buildFilterChips(AbstractThemeColors colors) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _statusFilterChip(
            colors: colors,
            label: 'filter_all'.tr(),
            selected: _filter == null,
            selectedColor: colors.activate,
            onSelected: (_) => setState(() => _filter = null),
          ),
          _statusFilterChip(
            colors: colors,
            label: 'cert_status_approved'.tr(),
            selected: _filter == CertStatus.approved,
            selectedColor: colors.certRingColor,
            onSelected: (_) => setState(() => _filter = CertStatus.approved),
          ),
          _statusFilterChip(
            colors: colors,
            label: 'cert_status_pending'.tr(),
            selected: _filter == CertStatus.pending,
            selectedColor: AppColors.statusPending,
            onSelected: (_) => setState(() => _filter = CertStatus.pending),
          ),
          _statusFilterChip(
            colors: colors,
            label: 'cert_status_rejected'.tr(),
            selected: _filter == CertStatus.rejected,
            selectedColor: colors.textSecondary,
            onSelected: (_) => setState(() => _filter = CertStatus.rejected),
          ),
        ],
      ),
    );
  }

  Widget _statusFilterChip({
    required AbstractThemeColors colors,
    required String label,
    required bool selected,
    required Color selectedColor,
    required void Function(bool) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        selectedColor: selectedColor.withValues(alpha: 0.12),
        checkmarkColor: selectedColor,
        backgroundColor: colors.surface,
        side: BorderSide(
          color: selected
              ? selectedColor
              : colors.textSecondary.withValues(alpha: 0.28),
          width: selected ? 1.5 : 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? selectedColor : colors.textSecondary,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    final displayed = _filtered;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.activate,
      child: _loading
          ? _buildSkeleton(colors)
          : _hasError
              ? _buildScrollable(
                  ErrorState(
                    message: 'err_fetch_data'.tr(),
                    onRetry: _load,
                  ),
                )
              : displayed.isEmpty
                  ? _buildScrollable(
                      EmptyState(
                        icon: Icons.verified_outlined,
                        title: 'cert_no_history'.tr(),
                        subtitle: _filter == null ? 'cert_no_history_hint'.tr() : null,
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: displayed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _CertCard(cert: displayed[index], certService: _certService);
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
            icon: Icon(Icons.add_photo_alternate_rounded, color: colors.certRingColor, size: 20),
            label: Text(
              'cert_submit'.tr(),
              style: TextStyle(color: colors.certRingColor, fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeSm),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(colors),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }
}

class _CertCard extends StatefulWidget {
  final CertificationModel cert;
  final CertificationService certService;

  const _CertCard({required this.cert, required this.certService});

  @override
  State<_CertCard> createState() => _CertCardState();
}

class _CertCardState extends State<_CertCard> {
  late int? _rating;
  late String? _review;
  bool _isSubmitting = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.cert.rating;
    _review = widget.cert.userReview;
  }

  Future<void> _navigateToFestival() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final festival = await sl<FestivalService>().fetchById(widget.cert.festivalId);
      if (!mounted) return;
      await Navigator.push(
        context,
        SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
      );
    } catch (e) {
      debugPrint('[CertCard] 페스티벌 이동 실패: $e');
    } finally {
      if (mounted) _isNavigating = false;
    }
  }

  Future<void> _openRatingSheet() async {
    if (_isSubmitting) return;
    final result = await showAppBottomSheet<({int rating, String? review})>(
      context,
      builder: (_) => RatingSheet(
        festivalTitle: widget.cert.festivalTitle,
        initialRating: _rating,
        initialReview: _review,
      ),
    );
    if (result == null) return;
    setState(() { _isSubmitting = true; });
    try {
      await widget.certService.submitRating(widget.cert.id, result.rating, result.review);
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
        setState(() { _isSubmitting = false; });
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
          _buildPosterImage(widget.cert.posterUrl, colors),
          _buildCardContent(colors, statusColor, statusLabel, isApproved, isPending),
        ],
      ),
    );
  }

  Widget _buildPosterImage(String? posterUrl, AbstractThemeColors colors) {
    return GestureDetector(
      onTap: _navigateToFestival,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        child: SizedBox(
          width: 90,
          height: 90,
          child: posterUrl != null
              ? CachedNetworkImage(
                  imageUrl: posterUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 180,
                  fadeInDuration: AppDimens.animXFast,
                  fadeOutDuration: AppDimens.animTapFeedback,
                  placeholder: (_, __) => const SkeletonBox(height: double.infinity),
                  errorWidget: (_, __, ___) => _buildPhotoPlaceholder(colors),
                )
              : _buildPhotoPlaceholder(colors),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color statusColor, String statusLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: AppDimens.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cert.festivalTitle,
              style: TextStyle(fontSize: AppDimens.fontSizeLg, fontWeight: FontWeight.w700, color: colors.textTitle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _buildStatusBadge(statusColor, statusLabel),
            _buildMeta(isPending, isApproved, widget.cert.rejectionMessage, widget.cert.formattedDate, colors),
            if (isApproved) ...[
              const SizedBox(height: 6),
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
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.activate),
      );
    }
    if (_rating != null) {
      return GestureDetector(
        onTap: _openRatingSheet,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(5, (i) => Icon(
              i < _rating! ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: Colors.amber,
            )),
            if (_review != null && _review!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _review!,
                  style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: _openRatingSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 14, color: colors.activate),
          const SizedBox(width: 4),
          Text(
            'rating_submit'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.activate),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(bool isPending, bool isApproved, String? rejectionMessage, String? createdAt, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isPending && !isApproved && rejectionMessage != null && rejectionMessage.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'cert_rejection_reason'.tr(args: [rejectionMessage]),
            style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (createdAt != null) ...[
          const SizedBox(height: 4),
          Text(createdAt, style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildPhotoPlaceholder(AbstractThemeColors colors) {
    return Container(
      color: colors.certRingColor.withValues(alpha: 0.1),
      child: Icon(Icons.photo_rounded,
          color: colors.textSecondary.withValues(alpha: 0.4), size: 32),
    );
  }
}

