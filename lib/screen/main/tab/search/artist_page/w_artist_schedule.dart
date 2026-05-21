import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_schedule_list.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_config.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class ArtistSchedule extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistSchedule({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistSchedule> createState() => _ArtistScheduleState();
}

class _ArtistScheduleState extends State<ArtistSchedule> {
  late Future<List<ArtistScheduleModel>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _fetchSchedule();
  }

  Future<List<ArtistScheduleModel>> _fetchSchedule() =>
      sl<ArtistScheduleService>().fetchSchedule(widget.artistId);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: AppDimens.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: AppDimens.cardRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          BoardCardHeader(
            icon: Icons.calendar_month_rounded,
            title: 'artist_schedule_title'.tr(args: [widget.artistName]),
            headerColor: colors.activate,
            onTap: () => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistScheduleListScreen(
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ),
            ),
          ),
          _buildScheduleList(colors),
        ],
      ),
    );
  }

  Widget _buildScheduleSkeleton() {
    return Column(
      children: List.generate(3, (i) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.all(Radius.circular(21)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 100, height: 11),
                        SizedBox(height: 4),
                        SkeletonBox(width: 130, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < 2)
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          ],
        );
      }),
    );
  }

  Widget _buildScheduleList(AbstractThemeColors colors) {
    return FutureBuilder<List<ArtistScheduleModel>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildScheduleSkeleton();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ErrorState(
              message: 'err_fetch_data'.tr(args: ['']),
              onRetry: () => setState(() {
                _scheduleFuture = _fetchSchedule();
              }),
            ),
          );
        }

        final upcoming = (snapshot.data ?? []).where((item) => !item.isPast).toList();

        if (upcoming.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'no_schedule'.tr(),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: upcoming.length,
          itemBuilder: (_, index) => _buildScheduleItem(upcoming[index], colors),
          separatorBuilder: (_, __) => Divider(
            thickness: 1,
            color: colors.listDivider,
            indent: AppDimens.paddingHorizontal,
            endIndent: AppDimens.paddingHorizontal,
          ),
        );
      },
    );
  }

  Widget _buildScheduleItem(ArtistScheduleModel item, AbstractThemeColors colors) {
    final typeConfig = getEventTypeConfig(item.eventType);
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
            child: hasPoster
                ? CachedNetworkImage(
                    imageUrl: item.posterUrl!,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => EventTypeIcon(config: typeConfig),
                  )
                : EventTypeIcon(config: typeConfig),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w700,
                    color: colors.textTitle,
                  ),
                ),
                if (item.location != null && item.location!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.location!,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXs,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (item.startDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        item.endDate != null && item.endDate != item.startDate
                            ? '${item.startDate} ~ ${item.endDate}'
                            : item.startDate!,
                        style: TextStyle(
                          fontSize: AppDimens.fontSizeXs,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.coArtists.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.coArtists.length,
                      itemBuilder: (_, i) {
                        final co = item.coArtists[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Tooltip(
                            message: co.artistName,
                            child: CircleAvatar(
                              radius: 13,
                              backgroundColor: colors.backgroundMain,
                              backgroundImage: (co.profileImageUrl != null &&
                                      co.profileImageUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(co.profileImageUrl!)
                                  : null,
                              child: (co.profileImageUrl == null ||
                                      co.profileImageUrl!.isEmpty)
                                  ? Icon(Icons.person_rounded,
                                      size: 12, color: colors.textSecondary)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}
