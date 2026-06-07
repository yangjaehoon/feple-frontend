import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
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
                if (notifier.hasError) return ErrorState(message: 'err_fetch_data'.tr(), onRetry: notifier.retry);
                if (notifier.artists.isEmpty) {
                  return Center(
                    child: Text(
                      'no_participating_artists'.tr(),
                      style: TextStyle(fontSize: 14, color: colors.textSecondary),
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
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    return _buildArtistCard(context, index, artist, isFollowed, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArtistCard(BuildContext context, int index, FestivalArtistItem artist, bool isFollowed, AbstractThemeColors colors) {
    return AnimatedListItem(
      index: index,
      child: TapScale(
        onTap: () => Navigator.push(
          context,
          SlideRoute(
            builder: (_) => ArtistPage(
              artistId: artist.artistId,
              artistName: artist.artistName,
              followerCount: 0,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  border: isFollowed
                      ? Border.all(color: colors.activate, width: 2.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isFollowed ? 17.5 : 20.0),
                  child: artist.profileImageUrl != null && artist.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: artist.profileImageUrl!,
                          memCacheWidth: 200,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SkeletonBox(height: double.infinity),
                          errorWidget: (_, __, ___) => _placeholderBox(colors),
                        )
                      : _placeholderBox(colors),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.artistName,
              style: TextStyle(
                fontSize: 13,
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

  Widget _placeholderBox(AbstractThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.person_rounded, color: colors.activate, size: 40),
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
      itemBuilder: (_, __) => const Column(
        children: [
          Expanded(
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          SizedBox(height: 8),
          SkeletonBox(width: 60, height: 13),
        ],
      ),
    );
  }
}
