import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/home/f_followed_artists_by_genre.dart';
import 'package:feple/screen/main/tab/home/f_liked_festivals_page.dart';
import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:feple/screen/main/tab/home/w_boards_section_skeleton.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:feple/screen/main/tab/home/w_home_artists_section.dart';
import 'package:feple/screen/main/tab/home/w_home_festivals_section.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/app_events.dart';
import '../../../../provider/user_provider.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({super.key});

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  final _notifier = HomeStateNotifier();

  @override
  void initState() {
    super.initState();
    AppEvents.festivalLikeChanged.addListener(_onFestivalLikeChanged);
    AppEvents.artistFollowChanged.addListener(_onArtistFollowChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<UserProvider>().currentUserId;
    if (userId != null && _notifier.userId != userId) {
      _notifier.init(userId);
    }
  }

  @override
  void dispose() {
    AppEvents.festivalLikeChanged.removeListener(_onFestivalLikeChanged);
    AppEvents.artistFollowChanged.removeListener(_onArtistFollowChanged);
    _notifier.dispose();
    super.dispose();
  }

  void _onFestivalLikeChanged() => _notifier.refreshFestivals();
  void _onArtistFollowChanged() => _notifier.refreshArtists();


  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        if (_notifier.userId == null) {
          return Container(
            color: colors.backgroundMain,
            child: Center(child: CircularProgressIndicator(color: colors.loadingIndicator)),
          );
        }
        return Container(
          color: colors.backgroundMain,
          child: Stack(
            children: [
              RefreshIndicator(
                color: colors.activate,
                onRefresh: () async => _notifier.refresh(force: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: AppDimens.scrollPaddingTop,
                    bottom: AppDimens.scrollPaddingBottom,
                  ),
                  child: _buildScrollContent(context, colors),
                ),
              ),
              const FepleAppBar("Feple"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollContent(BuildContext context, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'followed_artists'.tr(),
          onExpand: (_notifier.artists?.isNotEmpty ?? false)
              ? () async {
                  await Navigator.push(
                    context,
                    SlideRoute(
                      builder: (_) => FollowedArtistsByGenrePage(
                        artists: _notifier.orderedArtists ?? [],
                        onSaveOrder: _notifier.saveArtistOrder,
                      ),
                    ),
                  );
                  _notifier.refresh();
                }
              : null,
        ),
        HomeArtistsSection(
          artists: _notifier.orderedArtists,
          hasError: _notifier.hasError,
          onRetry: _notifier.retry,
          onTap: (artist) async {
            await Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistPage(
                  artistId: artist.id,
                  artistName: artist.name,
                  followerCounter: artist.followerCount,
                  profileImageUrl: artist.profileImageUrl,
                ),
              ),
            );
            _notifier.refresh();
          },
        ),
        const SizedBox(height: 8),
        HomeSectionHeader(
          title: 'liked_festivals'.tr(),
          onExpand: (_notifier.festivals?.isNotEmpty ?? false)
              ? () async {
                  await Navigator.push(
                    context,
                    SlideRoute(
                      builder: (_) => LikedFestivalsPage(
                        festivals: _notifier.orderedFestivals ?? [],
                        onSaveOrder: _notifier.saveFestivalOrder,
                      ),
                    ),
                  );
                  _notifier.refresh();
                }
              : null,
        ),
        HomeFestivalsSection(
          festivals: _notifier.orderedFestivals,
          hasError: _notifier.hasError,
          onRetry: _notifier.retry,
          onTap: (festival) async {
            await Navigator.push(
              context,
              SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
            );
            _notifier.refresh();
          },
        ),
        const SizedBox(height: 8),
        if (_notifier.hasError)
          const SizedBox.shrink()
        else if (_notifier.boards == null)
          const BoardsSectionSkeleton()
        else
          FavoriteBoardsSection(
            allBoards: _notifier.boards!,
            userId: _notifier.userId!,
          ),
      ],
    );
  }
}
