import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_schedule_list.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_skeleton.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_tile.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
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
  State<ArtistSchedule> createState() => ArtistScheduleState();
}

class ArtistScheduleState extends State<ArtistSchedule> with NavigationGuard {
  final _scheduleService = sl<ArtistScheduleService>();
  late Future<List<ArtistScheduleModel>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _fetchSchedule();
  }

  Future<List<ArtistScheduleModel>> _fetchSchedule() =>
      _scheduleService.fetchSchedule(widget.artistId);

  Future<void> refresh() async {
    final future = _fetchSchedule();
    setState(() => _scheduleFuture = future);
    try { await future; } catch (_) {}
  }

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
            onTap: () => guardedNavigate(() => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistScheduleListScreen(
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ),
            )),
          ),
          _buildScheduleList(colors),
        ],
      ),
    );
  }

  Widget _buildScheduleList(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<ArtistScheduleModel>>(
      future: _scheduleFuture,
      loadingBuilder: (_) => const ScheduleListSkeleton(),
      onRetry: () => setState(() { _scheduleFuture = _fetchSchedule(); }),
      isEmpty: (data) => data.every((item) => item.isPast),
      emptyBuilder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: EmptyState(icon: Icons.calendar_today_outlined, title: 'no_schedule'.tr()),
      ),
      useListViewForEmptyState: false,
      builder: (_, data) {
        final upcoming = data.where((item) => !item.isPast).toList();
        return Column(
          children: [
            for (int i = 0; i < upcoming.length; i++) ...[
              ScheduleListTile(item: upcoming[i]),
              if (i < upcoming.length - 1)
                Divider(
                  thickness: 1,
                  color: colors.listDivider,
                  indent: AppDimens.paddingHorizontal,
                  endIndent: AppDimens.paddingHorizontal,
                ),
            ],
          ],
        );
      },
    );
  }
}
