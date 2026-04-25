import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_preview_card.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';

class ConcertListWidget extends StatefulWidget {
  const ConcertListWidget({super.key});

  @override
  State<ConcertListWidget> createState() => _ConcertListWidgetState();
}

class _ConcertListWidgetState extends State<ConcertListWidget> {
  @override
  Widget build(BuildContext context) {
    final previewPoster = context.watch<FestivalPreviewProvider>();

    if (previewPoster.isLoading && previewPoster.items.isEmpty) {
      return _FestivalListSkeleton(colors: context.appColors);
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

    return Column(
      children: previewPoster.items.map((item) {
        return GestureDetector(
          onTap: () {
            final poster = FestivalModel(
              id: item.id,
              title: item.title,
              description: item.description,
              location: item.location,
              startDate: item.startDate,
              endDate: item.endDate ?? '',
              posterUrl: item.posterUrl,
              latitude: item.latitude,
              longitude: item.longitude,
            );
            Navigator.push(
              context,
              SlideRoute(
                builder: (context) =>
                    FestivalInformationFragment(poster: poster),
              ),
            );
          },
          child: FestivalPreviewCard(festival: item),
        );
      }).toList(),
    );
  }
}

class _FestivalListSkeleton extends StatelessWidget {
  final AbstractThemeColors colors;

  const _FestivalListSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (_) {
        return Container(
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(12),
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
