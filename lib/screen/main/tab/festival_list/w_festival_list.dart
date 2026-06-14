import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_preview_card.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';

class ConcertListWidget extends StatelessWidget {
  const ConcertListWidget({super.key});

  Widget _buildFestivalItem(BuildContext context, FestivalPreview item, int index) {
    return AnimatedListItem(
      index: index,
      child: TapScale(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            SlideRoute(
              builder: (context) => FestivalInformationFragment(poster: item.toModel()),
            ),
          );
        },
        child: FestivalPreviewCard(festival: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewPoster = context.watch<FestivalPreviewProvider>();

    if (previewPoster.isLoading && previewPoster.items.isEmpty) {
      return const _FestivalListSkeleton();
    }

    if (previewPoster.error != null && previewPoster.items.isEmpty) {
      return ErrorState(
        message: previewPoster.error!,
        onRetry: context.read<FestivalPreviewProvider>().refresh,
      );
    }

    if (previewPoster.items.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'no_festival_condition'.tr(),
      );
    }

    final items = previewPoster.items;
    return Column(
      children: List.generate(
        items.length,
        (index) => _buildFestivalItem(context, items[index], index),
      ),
    );
  }
}

class _FestivalListSkeleton extends StatelessWidget {
  const _FestivalListSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: List.generate(4, (_) {
        return Container(
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: SkeletonBox(
                  width: 80,
                  height: 120,
                  borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(height: 16),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 12),
                      SizedBox(height: 8),
                      SkeletonBox(width: 90, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
