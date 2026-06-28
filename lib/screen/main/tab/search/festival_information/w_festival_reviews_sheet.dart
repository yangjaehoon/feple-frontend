import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/model/cert_state.dart';
import 'package:feple/model/festival_review.dart';
import 'package:feple/screen/main/tab/my_page/w_rating_sheet.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';

class FestivalReviewsSheet extends StatefulWidget {
  final int festivalId;
  final CertificationService certService;
  final CertState certState;
  final String festivalTitle;
  final int? certId;
  final int? initialRating;
  final String? initialReview;
  final VoidCallback? onCertTap;

  const FestivalReviewsSheet({
    super.key,
    required this.festivalId,
    required this.certService,
    this.certState = CertState.none,
    this.festivalTitle = '',
    this.certId,
    this.initialRating,
    this.initialReview,
    this.onCertTap,
  });

  @override
  State<FestivalReviewsSheet> createState() => _FestivalReviewsSheetState();
}

class _FestivalReviewsSheetState extends State<FestivalReviewsSheet> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;

  double _averageRating = 0;
  int _ratingCount = 0;
  Map<int, int> _distribution = {};
  final List<FestivalReview> _reviews = [];
  int _page = 0;
  bool _hasNext = false;

  int? _myRating;
  String? _myReview;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _myRating = widget.initialRating;
    _myReview = widget.initialReview;
    _load(0);
  }

  void _openCertSheet() {
    Navigator.pop(context);
    widget.onCertTap?.call();
  }

  Future<void> _openRatingSheet() async {
    if (widget.certId == null) return;
    final result = await showAppBottomSheet<({int rating, String? review})>(
      context,
      useRootNavigator: true,
      builder: (_) => RatingSheet(
        festivalTitle: widget.festivalTitle,
        initialRating: _myRating,
        initialReview: _myReview,
      ),
    );
    if (result == null) return;
    setState(() => _isSubmittingRating = true);
    try {
      await widget.certService.submitRating(widget.certId!, result.rating, result.review);
      if (!mounted) return;
      setState(() {
        _myRating = result.rating;
        _myReview = result.review;
        _isSubmittingRating = false;
      });
      _load(0);
    } catch (e) {
      debugPrint('[ReviewsSheet] rating submit error: $e');
      if (!mounted) return;
      setState(() => _isSubmittingRating = false);
      context.showErrorSnackbar('rating_submit_failed'.tr());
    }
  }

  Future<void> _load(int page) async {
    if (page == 0) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    } else {
      if (_isLoadingMore || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }
    try {
      final data = await widget.certService.getFestivalReviews(
        widget.festivalId,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        if (page == 0) {
          _averageRating = data.averageRating;
          _ratingCount = data.ratingCount;
          _distribution = data.distribution;
          _reviews.clear();
          _isLoading = false;
        } else {
          _isLoadingMore = false;
        }
        _reviews.addAll(data.reviews);
        _page = page;
        _hasNext = data.hasNext;
      });
    } catch (e) {
      debugPrint('[ReviewsSheet] load error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (page == 0) _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.backgroundMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildSheetHeader(colors),
            Expanded(child: _buildBody(colors, scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: BottomSheetHandle()),
          const SizedBox(height: 14),
          Text(
            'reviews_sheet_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: colors.divider, height: 1),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors, ScrollController scrollController) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.activate),
      );
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              'reviews_load_failed'.tr(),
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _load(0),
              child: Text('retry'.tr(), style: TextStyle(color: colors.activate)),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _load(_page + 1);
        }
        return false;
      },
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          _buildMyRatingCta(colors),
          if (_ratingCount > 0) ...[
            Divider(color: colors.divider),
            _buildSummary(colors),
            Divider(color: colors.divider),
          ],
          if (_reviews.isEmpty)
            _buildEmpty(colors)
          else ...[
            ..._reviews.map((r) => _ReviewCard(review: r, colors: colors)),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyRatingCta(AbstractThemeColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: _buildCtaContent(colors),
    );
  }

  Widget _buildCtaContent(AbstractThemeColors colors) => switch (widget.certState) {
    CertState.pending => _buildPendingCta(colors),
    CertState.none => _buildNoCertCta(colors),
    CertState.certified => _isSubmittingRating ? _buildLoadingCta(colors) : _buildCertifiedCta(colors),
  };

  Widget _buildPendingCta(AbstractThemeColors colors) => Row(
    children: [
      Icon(Icons.hourglass_top_rounded, color: colors.textSecondary, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'reviews_cert_pending'.tr(),
          style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
        ),
      ),
    ],
  );

  Widget _buildNoCertCta(AbstractThemeColors colors) => Row(
    children: [
      Icon(Icons.workspace_premium_outlined, color: colors.certRingColor, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'reviews_cert_prompt'.tr(),
          style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textTitle),
        ),
      ),
      const SizedBox(width: 8),
      TextButton(
        onPressed: _openCertSheet,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'reviews_cert_btn'.tr(),
          style: TextStyle(color: colors.activate, fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeSm),
        ),
      ),
    ],
  );

  Widget _buildLoadingCta(AbstractThemeColors colors) => SizedBox(
    height: 24,
    child: Center(child: CircularProgressIndicator(color: colors.activate, strokeWidth: 2)),
  );

  Widget _buildCertifiedCta(AbstractThemeColors colors) => Row(
    children: [
      Icon(Icons.workspace_premium_rounded, color: colors.certRingColor, size: 16),
      const SizedBox(width: 8),
      Text(
        'reviews_my_rating'.tr(),
        style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: colors.textTitle),
      ),
      if (_myRating != null) ...[
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) => Icon(
            i < _myRating! ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 14,
          )),
        ),
      ],
      const Spacer(),
      TextButton(
        onPressed: _openRatingSheet,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          _myRating != null ? 'reviews_edit_rating'.tr() : 'reviews_leave_rating'.tr(),
          style: TextStyle(color: colors.activate, fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeSm),
        ),
      ),
    ],
  );

  Widget _buildSummary(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽: 큰 평점 숫자
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              _StarRow(rating: _averageRating, size: 16),
              const SizedBox(height: 6),
              Text(
                'reviews_count'.tr(args: ['$_ratingCount']),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXxs,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          // 오른쪽: 별점 분포 막대
          Expanded(child: _buildDistribution(colors)),
        ],
      ),
    );
  }

  Widget _buildDistribution(AbstractThemeColors colors) {
    final total = _distribution.values.fold(0, (a, b) => a + b);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [5, 4, 3, 2, 1].map((star) {
        final count = _distribution[star] ?? 0;
        final ratio = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
              const SizedBox(width: 3),
              Text(
                '$star',
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXxs,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.barRadius),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: colors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 22,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeXxs,
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmpty(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(Icons.star_outline_rounded, color: Colors.amber, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'reviews_no_reviews'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeLg,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'reviews_empty_hint'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (rating - i) >= 0.5;
        return Icon(
          filled
              ? Icons.star_rounded
              : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FestivalReview review;
  final AbstractThemeColors colors;

  const _ReviewCard({required this.review, required this.colors});

  @override
  Widget build(BuildContext context) {
    final initial = review.nickname.isNotEmpty
        ? review.nickname[0].toUpperCase()
        : '?';
    final hasReviewText =
        review.userReview != null && review.userReview!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타
              CircleAvatar(
                radius: 19,
                backgroundColor: colors.surface,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w700,
                    color: colors.activate,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.nickname,
                            style: TextStyle(
                              fontSize: AppDimens.fontSizeSm,
                              fontWeight: FontWeight.w600,
                              color: colors.textTitle,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.ratedAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            review.ratedAt!,
                            style: TextStyle(
                              fontSize: AppDimens.fontSizeXxs,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    _StarRow(rating: review.rating.toDouble(), size: 13),
                    if (hasReviewText) ...[
                      const SizedBox(height: 6),
                      Text(
                        review.userReview!,
                        style: TextStyle(
                          fontSize: AppDimens.fontSizeMd,
                          color: colors.textTitle,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.divider, height: 1),
        ],
      ),
    );
  }
}
