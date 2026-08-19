import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/festival_navigation.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_tile.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_skeleton.dart';
import 'package:flutter/material.dart';

class ArtistScheduleListScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistScheduleListScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistScheduleListScreen> createState() =>
      _ArtistScheduleListScreenState();
}

class _ArtistScheduleListScreenState extends State<ArtistScheduleListScreen>
    with
        FutureRefreshable<List<ArtistScheduleModel>,
            ArtistScheduleListScreen>,
        FestivalNavigationGuard<ArtistScheduleListScreen> {
  final _scheduleService = sl<ArtistScheduleService>();

  @override
  Future<List<ArtistScheduleModel>> fetchData() =>
      _scheduleService.fetchSchedule(widget.artistId);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: 'artist_schedule_title'.tr(args: [widget.artistName]),
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: refresh,
              child: FutureBuilder<List<ArtistScheduleModel>>(
                future: future,
                builder: (context, snapshot) => _buildBody(snapshot, colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<ArtistScheduleModel>> snapshot,
    AbstractThemeColors colors,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const ScheduleListSkeleton(itemCount: 6);
    }
    if (snapshot.hasError) {
      return ErrorState.network(snapshot.error!, onRetry: refresh);
    }
    final schedules = snapshot.data ?? [];
    if (schedules.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'no_schedule'.tr(),
          ),
        ],
      );
    }
    return _buildScheduleList(schedules, colors);
  }

  Widget _buildScheduleList(
    List<ArtistScheduleModel> schedules,
    AbstractThemeColors colors,
  ) {
    final upcoming = schedules.upcoming;
    final past = schedules.past.reversed.toList();

    final rows = <_ScheduleRow>[];
    if (upcoming.isNotEmpty) {
      rows.add(_ScheduleRow.header('schedule_upcoming'.tr()));
      for (final item in upcoming) {
        rows.add(_ScheduleRow.item(item, isPast: false));
      }
    }
    if (past.isNotEmpty) {
      rows.add(_ScheduleRow.header('schedule_past'.tr()));
      for (final item in past) {
        rows.add(_ScheduleRow.item(item, isPast: true));
      }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: rows.length,
      itemBuilder: (_, index) {
        final row = rows[index];
        if (row.isHeader) {
          return AnimatedListItem(
            index: index,
            child: _buildSectionHeader(row.label!, colors),
          );
        }
        final showDivider =
            index < rows.length - 1 && !rows[index + 1].isHeader;
        return AnimatedListItem(
          index: index,
          child: _buildItem(row.item!, row.isPast, showDivider, colors),
        );
      },
    );
  }

  Widget _buildSectionHeader(String label, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingHorizontal,
        16,
        AppDimens.paddingHorizontal,
        4,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(thickness: 1, color: colors.listDivider)),
        ],
      ),
    );
  }

  Widget _buildItem(
    ArtistScheduleModel item,
    bool isPast,
    bool showDivider,
    AbstractThemeColors colors,
  ) {
    return Column(
      children: [
        ScheduleListTile(
          item: item,
          isPast: isPast,
          isLoading: navigatingFestivalId == item.festivalId,
          onTap: () => navigateToFestival(item.festivalId),
          showCalendarAction: true,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: colors.listDivider,
            indent: AppDimens.paddingHorizontal,
            endIndent: AppDimens.paddingHorizontal,
          ),
      ],
    );
  }
}

class _ScheduleRow {
  final String? label;
  final ArtistScheduleModel? item;
  final bool isPast;

  const _ScheduleRow._({this.label, this.item, required this.isPast});

  factory _ScheduleRow.header(String label) =>
      _ScheduleRow._(label: label, isPast: false);
  factory _ScheduleRow.item(ArtistScheduleModel item, {required bool isPast}) =>
      _ScheduleRow._(item: item, isPast: isPast);

  bool get isHeader => label != null;
}
