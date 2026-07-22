import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class FestivalArtistListScreen extends StatelessWidget {
  final FestivalArtistsNotifier notifier;

  const FestivalArtistListScreen({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'participating_artists'.tr()),
          Expanded(
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, _) {
                if (notifier.isLoading) return _buildSkeleton();
                if (notifier.hasError) {
                  return ErrorState.network(
                    notifier.error!,
                    onRetry: notifier.retry,
                  );
                }
                if (notifier.artists.isEmpty) {
                  return Center(
                    child: Text(
                      'no_participating_artists'.tr(),
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeMd,
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }
                return _buildContent(colors);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    final displayed = notifier.displayedArtists;
    return Column(
      children: [
        if (notifier.hasDateFilter)
          DateTabBar(
            dates: notifier.allDates,
            selectedDate: notifier.selectedDate,
            onDateSelected: notifier.selectDate,
            allLabel: 'lineup_all'.tr(),
          ),
        Expanded(
          child: displayed.isEmpty
              ? Center(
                  child: Text(
                    'no_participating_artists'.tr(),
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final artist = displayed[index];
                    final isFollowed = notifier.isFollowed(artist.artistId);
                    return _buildArtistCard(context, index, artist, isFollowed);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArtistCard(
    BuildContext context,
    int index,
    FestivalArtistItem artist,
    bool isFollowed,
  ) {
    return AnimatedListItem(
      index: index,
      child: TapScale(
        onTap: () {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.push(
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
          );
        },
        child: ArtistCard(
          profileImageUrl: artist.profileImageUrl,
          name: artist.displayName(context.isEnglish),
          isFollowed: isFollowed,
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, _) => const Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimens.cardRadiusTiny),
              ),
            ),
          ),
          SizedBox(height: 8),
          SkeletonBox(width: 60, height: 13),
        ],
      ),
    );
  }
}
