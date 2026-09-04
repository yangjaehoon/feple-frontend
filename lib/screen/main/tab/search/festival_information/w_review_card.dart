import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_expandable_text.dart';
import 'package:feple/common/widget/w_star_rating_row.dart';
import 'package:feple/model/festival_review.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 페스티벌 리뷰 시트의 리뷰 한 건 — 아바타·닉네임·별점·본문 + 좋아요(낙관적).
class ReviewCard extends StatefulWidget {
  final FestivalReview review;
  final AbstractThemeColors colors;
  final CertificationService certService;

  const ReviewCard({
    super.key,
    required this.review,
    required this.colors,
    required this.certService,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late int _likeCount;
  late bool _likedByMe;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.review.likeCount;
    _likedByMe = widget.review.likedByMe;
  }

  Future<void> _toggleLike() async {
    if (_isSubmitting) return;
    if (!ensureLoggedIn(context)) return;
    unawaited(HapticFeedback.lightImpact());
    final wasLiked = _likedByMe;
    setState(() {
      _isSubmitting = true;
      _likedByMe = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      await widget.certService.toggleReviewLike(widget.review.reviewId);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    } catch (e) {
      debugPrint('[ReviewCard] like toggle error: $e');
      if (!mounted) return;
      setState(() {
        _likedByMe = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
        _isSubmitting = false;
      });
      context.showErrorSnackbar('like_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(colors),
              const SizedBox(width: AppDimens.space10),
              Expanded(child: _buildContent(colors)),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          _buildLikeButton(colors),
          const SizedBox(height: AppDimens.space10),
          Divider(color: colors.divider, height: 1),
        ],
      ),
    );
  }

  Widget _buildAvatar(AbstractThemeColors colors) {
    final nickname = widget.review.nickname;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: ResponsiveSize(context).w(19),
      backgroundColor: colors.surface,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: AppDimens.fontSizeMd,
          fontWeight: FontWeight.w700,
          color: colors.activate,
        ),
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    final review = widget.review;
    final hasReviewText =
        review.userReview != null && review.userReview!.isNotEmpty;
    return Column(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (review.ratedAt != null) ...[
              const SizedBox(width: AppDimens.space8),
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
        StarRatingRow(rating: review.rating.toDouble(), size: 13),
        if (hasReviewText) ...[
          const SizedBox(height: AppDimens.space6),
          ExpandableText(
            text: review.userReview!,
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.textTitle,
              height: 1.5,
            ),
            maxLines: 4,
          ),
        ],
      ],
    );
  }

  Widget _buildLikeButton(AbstractThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _toggleLike,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _likedByMe
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_up_outlined,
                  size: 14,
                  color: _likedByMe ? colors.activate : colors.textSecondary,
                ),
                if (_likeCount > 0) ...[
                  const SizedBox(width: AppDimens.space4),
                  Text(
                    '$_likeCount',
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXxs,
                      color: _likedByMe
                          ? colors.activate
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
