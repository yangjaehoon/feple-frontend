import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_config.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/festival_service.dart';
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
  State<ArtistScheduleListScreen> createState() => _ArtistScheduleListScreenState();
}

class _ArtistScheduleListScreenState extends State<ArtistScheduleListScreen> {
  late Future<List<ArtistScheduleModel>> _future;
  final _scheduleService = sl<ArtistScheduleService>();
  final _festivalService = sl<FestivalService>();

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<ArtistScheduleModel>> _fetch() =>
      _scheduleService.fetchSchedule(widget.artistId);

  Future<void> _refresh() async {
    setState(() => _future = _fetch());
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _navigateToFestival(int festivalId) async {
    try {
      final festival = await _festivalService.fetchById(festivalId);
      if (!mounted) return;
      Navigator.push(
        context,
        SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
      );
    } catch (e) {
      debugPrint('[ScheduleList] 페스티벌 이동 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'artist_schedule_title'.tr(args: [widget.artistName])),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _refresh,
              child: FutureBuilder<List<ArtistScheduleModel>>(
                future: _future,
                builder: (context, snapshot) =>
                    _buildBody(context, snapshot, colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<ArtistScheduleModel>> snapshot,
    AbstractThemeColors colors,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ErrorState(
        message: 'err_fetch_data'.tr(),
        onRetry: _refresh,
      );
    }
    final all = snapshot.data ?? [];
    if (all.isEmpty) {
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
    return _buildScheduleList(all, colors);
  }

  Widget _buildScheduleList(List<ArtistScheduleModel> all, AbstractThemeColors colors) {
    final upcoming = all.where((e) => !e.isPast).toList();
    final past = all.where((e) => e.isPast).toList();

    // flat list: [upcomingHeader?, ...upcoming, pastHeader?, ...past]
    final rows = <_Row>[];
    if (upcoming.isNotEmpty) {
      rows.add(_Row.header('schedule_upcoming'.tr()));
      for (final item in upcoming) { rows.add(_Row.item(item, isPast: false)); }
    }
    if (past.isNotEmpty) {
      rows.add(_Row.header('schedule_past'.tr()));
      for (final item in past) { rows.add(_Row.item(item, isPast: true)); }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: rows.length,
      itemBuilder: (_, index) {
        final row = rows[index];
        if (row.isHeader) return _buildSectionHeader(row.label!, colors);
        return _buildItem(row.item!, row.isPast, colors);
      },
    );
  }

  Widget _buildSectionHeader(String label, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.paddingHorizontal, 16, AppDimens.paddingHorizontal, 4),
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

  Widget _buildItem(ArtistScheduleModel item, bool isPast, AbstractThemeColors colors) {
    final typeConfig = getEventTypeConfig(item.eventType);
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Column(
        children: [
          InkWell(
            onTap: () => _navigateToFestival(item.festivalId),
            child: Padding(
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
          ),
          ),  // InkWell
          Divider(
            height: 1,
            thickness: 1,
            color: colors.listDivider,
            indent: AppDimens.paddingHorizontal,
            endIndent: AppDimens.paddingHorizontal,
          ),
        ],
      ),
    );
  }

}

class _Row {
  final String? label;
  final ArtistScheduleModel? item;
  final bool isPast;

  const _Row._({this.label, this.item, required this.isPast});

  factory _Row.header(String label) => _Row._(label: label, isPast: false);
  factory _Row.item(ArtistScheduleModel item, {required bool isPast}) =>
      _Row._(item: item, isPast: isPast);

  bool get isHeader => label != null;
}
