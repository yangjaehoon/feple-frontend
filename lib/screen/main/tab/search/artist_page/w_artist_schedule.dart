import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/model/artist_schedule_model.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_board_card_header.dart';
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

  Future<List<ArtistScheduleModel>> _fetchSchedule() async {
    final resp = await DioClient.dio.get('/artists/${widget.artistId}/schedule');
    return (resp.data as List)
        .map((e) => ArtistScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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
            title: '${widget.artistName} 일정',
            headerColor: colors.activate,
            onTap: () {},
          ),
          _buildScheduleList(colors),
        ],
      ),
    );
  }

  Widget _buildScheduleList(AbstractThemeColors colors) {
    return FutureBuilder<List<ArtistScheduleModel>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: colors.loadingIndicator),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '일정을 불러오지 못했습니다.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '등록된 일정이 없습니다.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (_, index) => _buildScheduleItem(items[index], colors),
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
    final typeConfig = _eventTypeConfig(item.eventType);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type circle icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: typeConfig.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: typeConfig.color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(typeConfig.icon, color: typeConfig.color, size: 20),
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
                                  ? NetworkImage(co.profileImageUrl!)
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

  _EventTypeConfig _eventTypeConfig(String eventType) {
    switch (eventType) {
      case 'FAN_MEETING':
        return _EventTypeConfig(
          icon: Icons.favorite_rounded,
          color: AppColors.kawaiiPink,
        );
      case 'TV_SHOW':
        return _EventTypeConfig(
          icon: Icons.tv_rounded,
          color: const Color(0xFFE0C3FC),
        );
      case 'FESTIVAL':
      default:
        return _EventTypeConfig(
          icon: Icons.music_note_rounded,
          color: AppColors.skyBlue,
        );
    }
  }
}

class _EventTypeConfig {
  final IconData icon;
  final Color color;
  const _EventTypeConfig({required this.icon, required this.color});
}
