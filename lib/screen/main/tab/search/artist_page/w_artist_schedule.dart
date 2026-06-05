import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_schedule_list.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_tile.dart';
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
    return SurfaceCard(
      width: double.infinity,
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
      children: List.generate(3, (index) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 12),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.all(Radius.circular(21)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
            if (index < 2)
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
              message: 'err_fetch_data'.tr(),
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
          itemBuilder: (_, index) => ScheduleListTile(item: upcoming[index]),
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
}
