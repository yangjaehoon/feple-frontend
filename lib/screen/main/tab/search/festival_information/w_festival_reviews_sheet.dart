import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/model/festival_review.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';

class FestivalReviewsSheet extends StatefulWidget {
  final int festivalId;
  final CertificationService certService;

  const FestivalReviewsSheet({
    super.key,
    required this.festivalId,
    required this.certService,
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

  @override
  void initState() {
    super.initState();
    _load(0);
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
          _buildSummary(colors),
          Divider(color: colors.divider),
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
                  borderRadius: BorderRadius.circular(2),
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
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Text(
          'reviews_no_reviews'.tr(),
          style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeMd),
        ),
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
