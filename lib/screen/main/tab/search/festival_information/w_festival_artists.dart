import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_circle_image.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artist_list.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FestivalArtists extends StatefulWidget {
  final int festivalId;

  const FestivalArtists({super.key, required this.festivalId});

  @override
  State<FestivalArtists> createState() => _FestivalArtistsState();
}

class _FestivalArtistsState extends State<FestivalArtists> {
  late final FestivalArtistsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    final userId = context.read<UserProvider>().currentUserId;
    _notifier = FestivalArtistsNotifier(
      festivalId: widget.festivalId,
      userId: userId,
      festivalService: sl<FestivalService>(),
      followService: sl<ArtistFollowService>(),
    );
    _notifier.fetch();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SurfaceCard(
      width: double.infinity,
      child: Column(
        children: [
          _buildHeader(colors),
          _buildArtistListArea(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return BoardCardHeader(
      icon: Icons.music_note_rounded,
      title: 'participating_artists'.tr(),
      headerColor: colors.activate,
      onTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => FestivalArtistListScreen(
            festivalId: widget.festivalId,
          ),
        ),
      ),
    );
  }

  Widget _padContent(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: 12,
        ),
        child: child,
      );

  Widget _buildArtistListArea(AbstractThemeColors colors) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        if (_notifier.isLoading) return _padContent(_buildSkeletonRow());
        if (_notifier.hasError) return _padContent(_buildErrorRow(colors));
        if (_notifier.artists.isEmpty) return _padContent(_buildEmptyRow(colors));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_notifier.hasDateFilter) _buildDateTabs(colors),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingHorizontal,
                vertical: 12,
              ),
              child: _buildArtistRow(colors),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateTabs(AbstractThemeColors colors) {
    return DateTabBar(
      dates: _notifier.allDates,
      selectedDate: _notifier.selectedDate,
      onDateSelected: _notifier.selectDate,
      allLabel: 'lineup_all'.tr(),
    );
  }

  Widget _buildArtistRow(AbstractThemeColors colors) {
    final displayed = _notifier.displayedArtists;
    if (displayed.isEmpty) {
      return _buildEmptyRow(colors);
    }
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayed.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final artist = displayed[index];
          final isFollowed = _notifier.isFollowed(artist.artistId);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistPage(
                  artistId: artist.artistId,
                  artistName: artist.artistName,
                  followerCounter: 0,
                ),
              ),
            ),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  ArtistCircleImage(
                    imageUrl: artist.profileImageUrl,
                    isFollowed: isFollowed,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.artistName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFollowed ? colors.activate : colors.textTitle,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => const SizedBox(
          width: 64,
          child: Column(
            children: [
              SkeletonBox(
                width: 56,
                height: 56,
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              SizedBox(height: 6),
              SkeletonBox(width: 40, height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRow(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'no_participating_artists'.tr(),
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildErrorRow(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'err_fetch_data'.tr(),
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _notifier.retry,
            child: Text(
              'retry'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.activate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

