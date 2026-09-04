import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_list_row_skeleton.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:feple/model/festival_review.dart';
import 'package:feple/screen/main/tab/my_page/w_rating_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_review_card.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_reviews_empty_state.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_reviews_my_rating_cta.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_reviews_summary.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';

class FestivalReviewsSheet extends StatefulWidget {
  final int festivalId;
  final CertificationService certService;
  final PosterCertState certState;
  final String festivalTitle;
  final int? certId;
  final int? initialRating;
  final String? initialReview;
  final VoidCallback? onCertTap;

  const FestivalReviewsSheet({
    super.key,
    required this.festivalId,
    required this.certService,
    this.certState = PosterCertState.none,
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
      isDismissible: false,
      enableDrag: false,
      builder: (_) => RatingSheet(
        festivalTitle: widget.festivalTitle,
        initialRating: _myRating,
        initialReview: _myReview,
      ),
    );
    if (result == null) return;
    setState(() => _isSubmittingRating = true);
    try {
      await widget.certService.submitRating(
        widget.certId!,
        result.rating,
        result.review,
      );
      if (!mounted) return;
      setState(() {
        _myRating = result.rating;
        _myReview = result.review;
        _isSubmittingRating = false;
      });
      unawaited(_load(0));
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.shapeSheet),
          ),
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
          const SizedBox(height: AppDimens.space12),
          Divider(color: colors.divider, height: 1),
        ],
      ),
    );
  }

  Widget _buildBody(
    AbstractThemeColors colors,
    ScrollController scrollController,
  ) {
    if (_isLoading) {
      return const ListRowSkeleton();
    }
    if (_hasError) {
      return ErrorState(
        message: 'reviews_load_failed'.tr(),
        onRetry: () => _load(0),
      );
    }

    // 헤더 항목: CTA(1) + 요약 있을 때 구분선·요약·구분선(3)
    final headerCount = _ratingCount > 0 ? 4 : 1;
    final reviewCount = _reviews.isEmpty
        ? 1
        : _reviews.length + (_isLoadingMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.pixels >=
                n.metrics.maxScrollExtent - AppDimens.loadMoreTriggerDistance) {
          _load(_page + 1);
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        itemCount: headerCount + reviewCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ReviewsMyRatingCta(
              certState: widget.certState,
              isSubmittingRating: _isSubmittingRating,
              myRating: _myRating,
              onCertTap: _openCertSheet,
              onRatingTap: _openRatingSheet,
            );
          }
          if (_ratingCount > 0) {
            if (index == 1) return Divider(color: colors.divider);
            if (index == 2) {
              return ReviewsSummary(
                averageRating: _averageRating,
                ratingCount: _ratingCount,
                distribution: _distribution,
              );
            }
            if (index == 3) return Divider(color: colors.divider);
          }
          final reviewIndex = index - headerCount;
          if (_reviews.isEmpty) return const ReviewsEmptyState();
          if (reviewIndex < _reviews.length) {
            final review = _reviews[reviewIndex];
            return AnimatedListItem(
              index: reviewIndex,
              child: ReviewCard(
                key: ValueKey(review.reviewId),
                review: review,
                colors: colors,
                certService: widget.certService,
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
