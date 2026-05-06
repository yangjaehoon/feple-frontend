import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
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
  final _festivalService = sl<FestivalService>();

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<ArtistScheduleModel>> _fetch() async {
    final resp = await DioClient.dio.get('/artists/${widget.artistId}/schedule');
    return (resp.data as List)
        .map((e) => ArtistScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetch());
    await _future;
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

  bool _isPast(ArtistScheduleModel item) {
    final dateStr = item.endDate ?? item.startDate;
    if (dateStr == null) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: SecondaryAppBar(
        title: 'artist_schedule_title'.tr(args: [widget.artistName]),
      ),
      backgroundColor: colors.backgroundMain,
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: _refresh,
        child: FutureBuilder<List<ArtistScheduleModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'err_fetch_data'.tr(args: ['']),
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

            final upcoming = all.where((e) => !_isPast(e)).toList();
            final past = all.where(_isPast).toList();

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
          },
        ),
      ),
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
    final typeConfig = _eventTypeConfig(item.eventType);
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
                          errorWidget: (_, __, ___) => _buildTypeIcon(typeConfig),
                        )
                      : _buildTypeIcon(typeConfig),
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

  Widget _buildTypeIcon(_EventTypeConfig config) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        border: Border.all(color: config.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(config.icon, color: config.color, size: 20),
    );
  }

  _EventTypeConfig _eventTypeConfig(String eventType) {
    switch (eventType) {
      case 'FAN_MEETING':
        return _EventTypeConfig(icon: Icons.favorite_rounded, color: AppColors.kawaiiPink);
      case 'TV_SHOW':
        return _EventTypeConfig(icon: Icons.tv_rounded, color: AppColors.kawaiiPurple);
      case 'FESTIVAL':
      default:
        return _EventTypeConfig(icon: Icons.music_note_rounded, color: AppColors.skyBlue);
    }
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

class _EventTypeConfig {
  final IconData icon;
  final Color color;
  const _EventTypeConfig({required this.icon, required this.color});
}
