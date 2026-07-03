import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:flutter/material.dart';

/// 별점·한줄평 입력 바텀시트.
/// Navigator.pop으로 ({rating, review})를 반환합니다.
class RatingSheet extends StatefulWidget {
  final String festivalTitle;
  final int? initialRating;
  final String? initialReview;

  const RatingSheet({
    super.key,
    required this.festivalTitle,
    this.initialRating,
    this.initialReview,
  });

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _selectedRating = 0;
  late final TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating ?? 0;
    _reviewController = TextEditingController(text: widget.initialReview ?? '');
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedRating == 0) return;
    final review = _reviewController.text.trim();
    Navigator.pop(context, (rating: _selectedRating, review: review.isEmpty ? null : review));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'rating_title'.tr(),
                  style: TextStyle(fontSize: AppDimens.fontSizeXxl, fontWeight: FontWeight.w700, color: colors.textTitle),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.festivalTitle,
                  style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _reviewController,
                  maxLength: 100,
                  maxLines: 2,
                  style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textTitle),
                  decoration: InputDecoration(
                    hintText: 'rating_review_hint'.tr(),
                    hintStyle: TextStyle(color: colors.textSecondary),
                    counterStyle: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXxs),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                LoadingButton(
                  label: 'done'.tr(),
                  onPressed: _selectedRating > 0 ? _submit : null,
                  isLoading: false,
                  backgroundColor: colors.activate,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
