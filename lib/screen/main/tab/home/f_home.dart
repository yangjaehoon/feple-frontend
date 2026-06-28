import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/home/s_followed_artists_by_genre.dart';
import 'package:feple/screen/main/tab/home/s_liked_festivals.dart';
import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:feple/screen/main/tab/home/w_boards_section_skeleton.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:feple/screen/main/tab/home/w_home_artists_section.dart';
import 'package:feple/screen/main/tab/home/w_home_festivals_section.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app.dart';
import '../../../../common/app_events.dart';
import '../../../../provider/user_provider.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({super.key});

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  final _notifier = HomeStateNotifier();
  final _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    AppEvents.festivalLikeChanged.addListener(_onFestivalLikeChanged);
    AppEvents.artistFollowChanged.addListener(_onArtistFollowChanged);
    App.resumeEvent.addListener(_onAppResumed);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.position.pixels > 300;
    if (show != _showScrollToTop) setState(() => _showScrollToTop = show);
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
    App.resumeEvent.removeListener(_onAppResumed);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _onFestivalLikeChanged() => _notifier.refreshFestivals();
  void _onArtistFollowChanged() => _notifier.refreshArtists();
  void _onAppResumed() => _notifier.refresh();


  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        ColoredBox(
          color: colors.backgroundMain,
          child: Column(
            children: [
              const FepleAppBar('Feple'),
              Expanded(
                child: ListenableBuilder(
                  listenable: _notifier,
                  builder: (context, _) {
                    if (_notifier.userId == null) {
                      return Center(child: CircularProgressIndicator(color: colors.loadingIndicator));
                    }
                    return RefreshIndicator(
                      color: colors.activate,
                      onRefresh: () async {
                        try {
                          await _notifier.refresh(force: true);
                        } catch (_) {
                          if (!context.mounted) return;
                          context.showErrorSnackbar('refresh_failed'.tr());
                        }
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
                        child: _buildScrollContent(context, colors),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_showScrollToTop)
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'homeScrollTop',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: AppDimens.animNormal,
                curve: Curves.easeOut,
              ),
              backgroundColor: colors.surface,
              foregroundColor: colors.textTitle,
              elevation: 2,
              child: const Icon(Icons.arrow_upward_rounded, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildScrollContent(BuildContext context, AbstractThemeColors colors) {
    final orderedArtists = _notifier.orderedArtists;
    final orderedFestivals = _notifier.orderedFestivals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'followed_artists'.tr(),
          onExpand: (_notifier.artists?.isNotEmpty ?? false)
              ? () => Navigator.push(
                    context,
                    SlideRoute(
                      builder: (_) => FollowedArtistsByGenreScreen(
                        artists: orderedArtists ?? [],
                        onSaveOrder: _notifier.saveArtistOrder,
                      ),
                    ),
                  )
              : null,
        ),
        HomeArtistsSection(
          artists: orderedArtists,
          hasError: _notifier.hasError,
          onRetry: _notifier.retry,
          onShowMore: (orderedArtists != null && orderedArtists.length > HomeArtistsSection.maxPreview)
              ? () => Navigator.push(
                    context,
                    SlideRoute(
                      builder: (_) => FollowedArtistsByGenreScreen(
                        artists: orderedArtists,
                        onSaveOrder: _notifier.saveArtistOrder,
                      ),
                    ),
                  )
              : null,
          onTap: (artist) => Navigator.push(
            context,
            SlideRoute(
              builder: (_) => ArtistScreen(
                artistId: artist.id,
                artistName: artist.name,
                followerCount: artist.followerCount,
                profileImageUrl: artist.profileImageUrl,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        HomeSectionHeader(
          title: 'liked_festivals'.tr(),
          onExpand: (_notifier.festivals?.isNotEmpty ?? false)
              ? () => Navigator.push(
                    context,
                    SlideRoute(
                      builder: (_) => LikedFestivalsScreen(
                        festivals: orderedFestivals ?? [],
                        onSaveOrder: _notifier.saveFestivalOrder,
                      ),
                    ),
                  )
              : null,
        ),
        HomeFestivalsSection(
          festivals: orderedFestivals,
          hasError: _notifier.hasError,
          onRetry: _notifier.retry,
          onTap: (festival) => Navigator.push(
            context,
            SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
          ),
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
