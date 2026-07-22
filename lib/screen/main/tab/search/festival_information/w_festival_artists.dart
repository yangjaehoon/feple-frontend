import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_circle_image.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_artist_list.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FestivalArtists extends StatefulWidget {
  final int festivalId;

  const FestivalArtists({super.key, required this.festivalId});

  @override
  State<FestivalArtists> createState() => FestivalArtistsState();
}

class FestivalArtistsState extends State<FestivalArtists> with NavigationGuard {
  late final FestivalArtistsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    final userId = context.read<UserProvider>().currentUserId;
    _notifier = FestivalArtistsNotifier(
      festivalId: widget.festivalId,
      userId: userId,
      festivalService: sl<FestivalDetailService>(),
      followService: sl<ArtistFollowService>(),
    );
    _notifier.fetch();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void refresh() => _notifier.fetch();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SurfaceCard(
      width: double.infinity,
      child: Column(
        children: [_buildHeader(colors), _buildArtistListArea(colors)],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return BoardCardHeader(
      icon: Icons.music_note_rounded,
      title: 'participating_artists'.tr(),
      headerColor: colors.activate,
      onTap: () => guardedNavigate(
        () => Navigator.push(
          context,
          SlideRoute(
            builder: (_) => FestivalArtistListScreen(notifier: _notifier),
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
        if (_notifier.hasError) {
          return ErrorState.network(_notifier.error!, onRetry: _notifier.retry);
        }
        if (_notifier.artists.isEmpty) {
          return _padContent(_buildEmptyRow(colors));
        }
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

  static const int _maxVisible = 10;

  Widget _buildArtistRow(AbstractThemeColors colors) {
    final displayed = _notifier.displayedArtists;
    if (displayed.isEmpty) {
      return _buildEmptyRow(colors);
    }
    final hasMore = displayed.length > _maxVisible;
    final visible = hasMore ? displayed.sublist(0, _maxVisible) : displayed;
    final rowHeight = MediaQuery.sizeOf(context).width * 0.205; // 80/390
    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (hasMore && index == visible.length) {
            return _buildMoreItem(colors);
          }
          final artist = visible[index];
          final isFollowed = _notifier.isFollowed(artist.artistId);
          return _buildArtistItem(context, artist, isFollowed, colors);
        },
      ),
    );
  }

  Widget _buildMoreItem(AbstractThemeColors colors) {
    return GestureDetector(
      onTap: () => guardedNavigate(
        () => Navigator.push(
          context,
          SlideRoute(
            builder: (_) => FestivalArtistListScreen(notifier: _notifier),
          ),
        ),
      ),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.backgroundMain,
                shape: BoxShape.circle,
                border: Border.all(color: colors.listDivider),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                size: 22,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'see_more'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXxs,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(
    BuildContext context,
    FestivalArtistItem artist,
    bool isFollowed,
    AbstractThemeColors colors,
  ) {
    return GestureDetector(
      onTap: () => guardedNavigate(
        () => Navigator.push(
          context,
          SlideRoute(
            builder: (_) => ArtistScreen(
              artistId: artist.artistId,
              artistName: artist.artistName,
              artistNameEn: artist.artistNameEn,
              followerCount: 0,
              profileImageUrl: artist.profileImageUrl,
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ArtistCircleImage(
              imageUrl: artist.profileImageUrl,
              isFollowed: isFollowed,
            ),
            const SizedBox(height: 6),
            Text(
              artist.displayName(context.isEnglish),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXxs,
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
  }

  Widget _buildSkeletonRow() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).width * 0.205, // 80/390
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) => const SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
